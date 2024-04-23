import { debounce } from '../../../utils/debounce';
import createModal from './modalWindow';

// if (process.env.NODE_ENV !== 'production') {
//   require('webpack-dev-server/client?http://localhost:3000');
// }
// 禁用Webpack Dev Server客户端, 以避免与Chrome扩展程序的热重载冲突

console.log('Content script works!');
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
  console.log('DOM fully loaded and parsed');
  const observer = new MutationObserver((mutations, obs) => {
    const targetButton = document.querySelector(
      'div[data-testid="tweetButtonInline"]'
    );
    if (targetButton) {
      obs.disconnect(); // 找到后断开观察
      console.log('发推按钮已找到');
      const injectButton = document.createElement('button');
      injectButton.innerText = '发起抽奖';
      injectButton.style.cssText = `
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 10px;
      background-color: rgb(29, 155, 240); 
      color: white;
      border: none;
      border-radius: 9999px; 
      padding: 6px 16px; 
      cursor: pointer;
      font-size: 15px;
      font-weight: bold;
      text-transform: none;
      -webkit-box-shadow: none; 
      box-shadow: none;
      `;

      // // 使用防抖函数封装按钮点击事件
      // const debouncedClick = debounce(() => {
      //   // alert('在这里实现设置界面和合约交互的逻辑');
      //   createModal();
      // }, 0); // 延迟（如果需要）
      let isModalCreated = false;
      if (!isModalCreated) {
        injectButton.addEventListener('click', createModal);
        isModalCreated = true;
      }

      // 将按钮插入到发帖按钮前
      targetButton.style.display = 'flex';
      targetButton.style.alignItems = 'center';
      targetButton.parentNode.insertBefore(injectButton, targetButton);
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });
}
