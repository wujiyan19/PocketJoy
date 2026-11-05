import { appTasks, OhosAppContext, OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import { HvigorNode } from '@ohos/hvigor';
import * as fs from 'node:fs';
import * as path from 'node:path';

export default {
  system: appTasks,
  plugins: [{
    pluginId: 'little-games-local-signing',
    apply(node: HvigorNode): void {
      // 在子模块创建签名任务前注入内存配置，IDE 与命令行均不向共享文件写入口令。
      const context = node.getContext(OhosPluginId.OHOS_APP_PLUGIN) as OhosAppContext;
      const localPath = path.join(context.getProjectPath(), 'signing.local.json');
      if (!fs.existsSync(localPath)) { return; }
      const local = JSON.parse(fs.readFileSync(localPath, 'utf8'));
      const profile = context.getBuildProfileOpt();
      profile.app.signingConfigs = local.signingConfigs;
      for (const product of profile.app.products) {
        const signing = local.products.find((item: { name: string; signingConfig: string }) => item.name === product.name);
        if (signing) { product.signingConfig = signing.signingConfig; }
      }
      context.setBuildProfileOpt(profile);
    }
  }]
};
