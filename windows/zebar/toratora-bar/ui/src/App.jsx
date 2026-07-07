import React, { useEffect, useMemo, useRef, useState } from 'react';
import * as zebar from 'zebar';

/* ── Providers (native, event-driven) ─────────────────────── */
const providers = zebar.createProviderGroup({
  cpu:     { type: 'cpu' },
  memory:  { type: 'memory' },
  battery: { type: 'battery' },
  network: { type: 'network', refreshInterval: 3000 },
  audio:   { type: 'audio' },
  media:   { type: 'media' },
  glazewm: { type: 'glazewm' },
});

/* ── Hooks ─────────────────────────────────────────────────── */

/** Second-aligned clock. Ticks exactly on each second boundary. */
function useClock() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    let intervalId;
    // align first tick to the next second boundary
    const timeoutId = setTimeout(() => {
      setNow(new Date());
      intervalId = setInterval(() => setNow(new Date()), 1000);
    }, 1000 - (Date.now() % 1000));
    return () => { clearTimeout(timeoutId); clearInterval(intervalId); };
  }, []);
  return now;
}

/**
 * Single consolidated PowerShell poll (GPU / temp / VPN) every 10s.
 * One process instead of three → far fewer CPU spikes.
 */
const STATS_PS = [
  "$g=try{[int]((Get-Counter '\\GPU Engine(*engtype_3D*)\\Utilization Percentage' -EA Stop).CounterSamples|Measure-Object -Property CookedValue -Sum).Sum}catch{-1};",
  "$t=try{$x=(Get-CimInstance -Namespace root/WMI -ClassName MSAcpi_ThermalZoneTemperature -EA Stop).CurrentTemperature;if($x){[int]($x[0]/10-273.15)}else{-1}}catch{-1};",
  "$v=if((Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match 'VPN|TAP|WireGuard|OpenVPN|Surfshark|NordVPN|ProtonVPN' -and $_.Status -eq 'Up'}).Count -gt 0){1}else{0};",
  '"{""gpu"":$g,""temp"":$t,""vpn"":$v}"',
].join('');

function useSystemStats() {
  const [stats, setStats] = useState({ gpu: null, temp: null, vpn: false });
  useEffect(() => {
    let alive = true;
    const poll = async () => {
      try {
        const r = await zebar.shellExec('powershell', ['-NoProfile', '-Command', STATS_PS]);
        const j = JSON.parse(r.stdout?.trim() ?? '{}');
        if (!alive) return;
        setStats({
          gpu:  j.gpu  > 0 ? Math.min(99, j.gpu) : null,
          temp: j.temp > 0 ? j.temp : null,
          vpn:  j.vpn === 1,
        });
      } catch { /* keep previous values */ }
    };
    poll();
    const id = setInterval(poll, 10000);
    return () => { alive = false; clearInterval(id); };
  }, []);
  return stats;
}

/** GitHub push-event commit count for today (JST), every 5 min. */
function useCommits(user) {
  const [commits, setCommits] = useState(null);
  useEffect(() => {
    const fetchCommits = async () => {
      try {
        const today = new Date().toLocaleDateString('sv-SE');
        const res = await fetch(`https://api.github.com/users/${user}/events?per_page=100`);
        if (!res.ok) return;
        const events = await res.json();
        setCommits(events
          .filter(e => e.type === 'PushEvent' && (e.created_at ?? '').startsWith(today))
          .reduce((s, e) => s + (e.payload?.commits?.length ?? 0), 0));
      } catch { /* offline / rate-limited */ }
    };
    fetchCommits();
    const id = setInterval(fetchCommits, 5 * 60 * 1000);
    return () => clearInterval(id);
  }, [user]);
  return commits;
}

/* ── Helpers ───────────────────────────────────────────────── */

const n2 = v => String(Math.min(99, Math.max(0, Math.round(v)))).padStart(2, ' ');

const fmtSpeed = m => {
  if (!m) return '0';
  const v = m.siValue ?? 0;
  return `${v >= 100 ? Math.round(v) : v.toFixed(v >= 10 ? 0 : 1)}${(m.siUnit ?? 'B').replace('B', '')}`;
};

const sigLevel = s =>
  s == null ? 'none' : s >= 70 ? 'good' : s >= 40 ? 'mid' : 'bad';

const batColor = (pct, charging) => {
  if (charging) return 'var(--green)';
  // hue 120 (green) → 0 (red), skewed so it stays green longer
  const h = Math.round(Math.max(0, Math.min(120, (pct - 10) * 1.5)));
  return `hsl(${h} 70% 62%)`;
};

/* ── App ───────────────────────────────────────────────────── */

export default function App() {
  const [output, setOutput] = useState(providers.outputMap);
  const [showSec, setShowSec] = useState(false);
  const [netOpen, setNetOpen] = useState(false);

  const now = useClock();
  const { gpu, temp, vpn } = useSystemStats();
  const commits = useCommits('ToraMutton');

  useEffect(() => {
    providers.onOutput(() => setOutput(providers.outputMap));
  }, []);

  /* time */
  const DAY_JP = ['日', '月', '火', '水', '木', '金', '土'];
  const dayK = DAY_JP[now.getDay()];
  const mo = String(now.getMonth() + 1).padStart(2, '0');
  const dy = String(now.getDate()).padStart(2, '0');
  const hh = String(now.getHours()).padStart(2, '0');
  const mm = String(now.getMinutes()).padStart(2, '0');
  const ss = String(now.getSeconds()).padStart(2, '0');
  const sec = now.getSeconds();

  /* providers */
  const cpuPct = Math.round(output.cpu?.usage ?? 0);
  const memPct = Math.round(output.memory?.usage ?? 0);
  const bat = output.battery;
  const vol = output.audio?.defaultPlaybackDevice;
  const media = output.media?.currentSession;
  const wsList = output.glazewm?.currentWorkspaces ?? [];
  const focusedTitle = output.glazewm?.focusedContainer?.title ?? null;

  /* network — signal/ssid live on defaultGateway, iface info on defaultInterface */
  const iface = output.network?.defaultInterface;
  const gw = output.network?.defaultGateway;
  const traffic = output.network?.traffic;
  const sig = gw?.signalStrength ?? null;
  const sigCls = sigLevel(sig);
  const netName =
    iface?.type === 'wifi' ? (gw?.ssid || 'WiFi')
    : iface?.type === 'ethernet' ? 'LAN'
    : iface ? '──' : null;

  const openWifiSettings = () => {
    zebar.shellExec('cmd', ['/c', 'start', 'ms-availablenetworks:']).catch(() => {});
  };

  const sigBars = useMemo(() => {
    const filled = Math.round(Math.min(100, Math.max(0, sig ?? 0)) / 25);
    return '▇'.repeat(filled) + '░'.repeat(4 - filled);
  }, [sig]);

  const batPct = bat ? Math.round(bat.chargePercent) : 0;

  return (
    <div id="app">

      {/* ── LEFT: workspaces + window title ── */}
      <div className="section left">
        <div className="workspaces">
          {wsList.map(ws => (
            <span key={ws.name} className={`ws ${ws.hasFocus ? 'ws-on' : 'ws-off'}`}>
              {ws.displayName ?? ws.name}
            </span>
          ))}
        </div>
        {focusedTitle && (
          <>
            <span className="sep-arrow"> › </span>
            <span className="win-title" key={focusedTitle}>
              {focusedTitle.length > 38 ? focusedTitle.slice(0, 38) + '…' : focusedTitle}
            </span>
          </>
        )}
      </div>

      {/* ── CENTER: clock (second-aligned) ── */}
      <div className="section center">
        <span className="c-day">({dayK})</span>
        <span className="c-date">{mo}.{dy}</span>
        <span className="c-sep"> · </span>
        <span className="c-time" onClick={() => setShowSec(v => !v)} title="クリックで秒表示切替">
          {hh}
          {/* key=sec remounts the colon each tick → blink is always in phase */}
          <span className="c-colon" key={sec}>:</span>
          {mm}
          {showSec && <><span className="c-colon" key={`s${sec}`}>:</span><span className="c-sec">{ss}</span></>}
        </span>
      </div>

      {/* ── RIGHT: stats ── */}
      <div className="section right">

        <span className="stat cpu">CPU:<span className="val">{n2(cpuPct)}</span></span>
        <span className="stat mem">MEM:<span className="val">{n2(memPct)}</span></span>
        {gpu  !== null && <span className="stat gpu">GPU:<span className="val">{n2(gpu)}</span></span>}
        {temp !== null && <span className="stat temp"><span className="val-bare">{temp}</span>°</span>}

        <span className="dot">·</span>

        {/* WiFi: colored signal, live speed, hover detail, click → settings */}
        {iface && (
          <span
            className={`stat net sig-${sigCls}`}
            onMouseEnter={() => setNetOpen(true)}
            onMouseLeave={() => setNetOpen(false)}
            onClick={openWifiSettings}
            title="クリックでWi-Fi設定"
          >
            <span className="sig">{sigBars}</span>
            <span className="net-name">{netName}</span>
            {traffic && (
              <span className="net-speed">
                <span className="arrow">↓</span>{fmtSpeed(traffic.received)}
                {' '}
                <span className="arrow">↑</span>{fmtSpeed(traffic.transmitted)}
              </span>
            )}
            {/* inline expansion — the 36px bar can't overflow, so details slide in */}
            <span className={`net-detail${netOpen ? ' open' : ''}`}>
              {sig != null && <>{sig}%&ensp;</>}
              {iface.ipv4Addresses?.[0] && <>IP {iface.ipv4Addresses[0]}&ensp;</>}
              {iface.receiveSpeed ? <>Link {Math.round(iface.receiveSpeed / 1e6)}Mbps</> : null}
            </span>
          </span>
        )}

        <span className="dot">·</span>

        {vol && (
          <span className="stat vol">
            {vol.isMuted
              ? <span className="muted">VOL:──</span>
              : <>VOL:<span className="val">{n2(Math.round(vol.volume))}</span></>}
          </span>
        )}

        {/* Battery gauge: bar + gradient color + charging animation */}
        {bat && (
          <span
            className={`stat bat-wrap${batPct < 15 && !bat.isCharging ? ' bat-crit' : ''}`}
            title={bat.isCharging
              ? `充電中${bat.timeTillFull ? ` (満充電まで ${Math.round(bat.timeTillFull / 60000)}分)` : ''}`
              : `残り${bat.timeTillEmpty ? ` ${Math.round(bat.timeTillEmpty / 60000)}分` : ''}`}
          >
            <span className="bat-gauge">
              <span
                className={`bat-fill${bat.isCharging ? ' charging' : ''}`}
                style={{ width: `${batPct}%`, background: batColor(batPct, bat.isCharging) }}
              />
              {bat.isCharging && <span className="bat-bolt">⚡</span>}
            </span>
            <span className="bat-num" style={{ color: batColor(batPct, bat.isCharging) }}>
              {batPct}<span className="pct-sign">%</span>
            </span>
          </span>
        )}

        <span className="dot">·</span>

        {media?.title && (
          <span className="stat music" key={media.title}>
            ♫ {media.title.length > 20 ? media.title.slice(0, 20) + '…' : media.title}
          </span>
        )}

        {vpn && <span className="stat vpn">[VPN]</span>}
        {commits !== null && <span className="stat commits">↑{commits}</span>}

      </div>
    </div>
  );
}
