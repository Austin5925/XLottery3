import { debounce } from '../../../utils/debounce';

console.log('Content script works!');

if (process.env.NODE_ENV !== 'production') {
  require('webpack-dev-server/client?http://localhost:3000');
}
// 禁用Webpack Dev Server客户端, 以避免与Chrome扩展程序的热重载冲突

// 等待DOM完全加载

if (
  document.readyState === 'complete' ||
  document.readyState === 'interactive'
) {
  // DOM已准备好，直接执行函数
  runMyFunction();
} else {
  // 否则，等待DOMContentLoaded事件
  document.addEventListener('DOMContentLoaded', runMyFunction);
}

function runMyFunction() {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM fully loaded and parsed');
    const targetButton = document.querySelector(
      'div[data-testid="tweetButtonInline"]'
    );

    if (targetButton) {
      const injectButton = document.createElement('button');
      injectButton.innerText = '创建有奖推文';
      injectButton.style.cssText = `
      margin-right: 10px;
      background-color: #1DA1F2;
      color: white;
      border: none;
      border-radius: 20px;
      padding: 10px;
      cursor: pointer;
    `;

      // 使用防抖函数封装按钮点击事件
      const debouncedClick = debounce(() => {
        alert('在这里实现设置界面和合约交互的逻辑');
        // ethers.js 的具体实现根据您的合约来定
      }, 300); // 延迟300毫秒

      injectButton.addEventListener('click', debouncedClick);

      // 将按钮插入到发帖按钮前
      targetButton.style.display = 'flex';
      targetButton.style.alignItems = 'center';
      targetButton.parentNode.insertBefore(injectButton, targetButton);
    }
  });
}
