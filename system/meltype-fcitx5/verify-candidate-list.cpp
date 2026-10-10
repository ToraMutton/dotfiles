// candidate-list.patch の確認用テスト。build.sh が Meltype の test/testmeltype.cpp と差し替えて実行する。
// 「kou」を変換して Space を 11 回押し (10 番目以降の候補を選んだ状態)、次を確かめる:
//   - 候補の一覧が縦並び (Mozc と同じ) になっている
//   - 選んでいる候補のあるページが表示されている (1 ページ目のままになっていない)

#include <testfrontend_public.h>
#include <fcitx-utils/eventdispatcher.h>
#include <fcitx-utils/log.h>
#include <fcitx-utils/testing.h>
#include <fcitx/addonmanager.h>
#include <fcitx/candidatelist.h>
#include <fcitx/inputcontextmanager.h>
#include <fcitx/inputmethodgroup.h>
#include <fcitx/inputmethodmanager.h>
#include <fcitx/inputpanel.h>
#include <fcitx/instance.h>

#include <cstdio>

using namespace fcitx;

namespace {

void tap(AddonInstance *frontend, ICUUID uuid, const std::string &name) {
    frontend->call<ITestFrontend::keyEvent>(uuid, Key(name), false);
    frontend->call<ITestFrontend::keyEvent>(uuid, Key(name), true);
}

void scheduleEvent(EventDispatcher *dispatcher, Instance *instance) {
    dispatcher->schedule([dispatcher, instance]() {
        auto *frontend = instance->addonManager().addon("testfrontend");
        FCITX_ASSERT(instance->addonManager().addon("meltype", true)) << "Meltype のアドオンを読めません";
        auto group = instance->inputMethodManager().currentGroup();
        group.inputMethodList().clear();
        group.inputMethodList().push_back(InputMethodGroupItem("keyboard-us"));
        group.inputMethodList().push_back(InputMethodGroupItem("meltype"));
        group.setDefaultInputMethod("");
        instance->inputMethodManager().setGroup(group);
        auto uuid = frontend->call<ITestFrontend::createInputContext>("testapp");
        auto *ic = instance->inputContextManager().findByUUID(uuid);
        FCITX_ASSERT(ic);
        instance->setCurrentInputMethod(ic, "meltype", true);

        for (char c : std::string("kou")) tap(frontend, uuid, std::string(1, c));
        for (int i = 0; i < 11; i++) tap(frontend, uuid, "space");

        auto list = ic->inputPanel().candidateList();
        FCITX_ASSERT(list) << "変換の候補の一覧が出ない";
        auto *pageable = list->toPageable();
        auto *bulk = list->toBulk();
        std::printf("candidates=%d page=%d cursor=%d vertical=%d\n", bulk ? bulk->totalSize() : -1,
                    pageable ? pageable->currentPage() : -1, list->cursorIndex(),
                    list->layoutHint() == CandidateLayoutHint::Vertical);
        std::fflush(stdout);
        FCITX_ASSERT(list->layoutHint() == CandidateLayoutHint::Vertical) << "候補が縦並びになっていない";
        FCITX_ASSERT(list->cursorIndex() >= 0) << "選んでいる候補が、表示しているページに無い";
        FCITX_ASSERT(pageable && pageable->currentPage() >= 1) << "1 ページ目のまま";
        tap(frontend, uuid, "Escape");

        dispatcher->schedule([dispatcher, instance]() {
            dispatcher->detach();
            instance->exit();
        });
    });
}

} // namespace

int main() {
    setupTestingEnvironment(FCITX5_MELTYPE_BINARY_DIR, {FCITX5_MELTYPE_BINARY_DIR, FCITX5_SYSTEM_ADDON_DIR}, {"test"});
    char arg0[] = "testmeltype";
    char arg1[] = "--disable=all";
    char arg2[] = "--enable=testfrontend,testui,testim,keyboard,meltype";
    char *argv[] = {arg0, arg1, arg2};
    fcitx::Log::setLogRule("default=1");
    Instance instance(FCITX_ARRAY_SIZE(argv), argv);
    instance.addonManager().registerDefaultLoader(nullptr);
    EventDispatcher dispatcher;
    dispatcher.attach(&instance.eventLoop());
    scheduleEvent(&dispatcher, &instance);
    return instance.exec();
}
