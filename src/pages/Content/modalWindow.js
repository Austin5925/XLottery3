function createModal() {
  const modal = document.createElement('div');
  modal.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-color: rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
      visibility: visible;
  `;

  const modalContent = document.createElement('div');
  modalContent.style.cssText = `
      background-color: white;
      padding: 20px;
      border-radius: 10px;
      width: 50%;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  `;
  modalContent.innerHTML = `
  <div class="modal-overlay">
    <div class="modal-content">
      <h2>设置抽奖详情</h2>
      <form id="lotteryForm">
        <label>
          <input type="checkbox" name="requireRetweet" />
          要求转发
        </label>
        <label>
          <input type="checkbox" name="requireLike" />
          要求点赞
        </label>
        <div>
          <label>
            截止时间:
            <input type="datetime-local" name="deadline" />
          </label>
        </div>
        <h3>奖项设置</h3>
        <div id="prizesContainer">
          <button type="button" id="addPrizeButton">添加奖项</button>
        </div>
        
        <button type="submit">提交设置</button>
        <button type="button" id="closeModalButton">关闭</button>
      </form>
    </div>
  </div>
  `;

  modal.appendChild(modalContent);
  document.body.appendChild(modal);

  // 添加奖项与动态删除

  console.log('3');
  document.getElementById('addPrizeButton').addEventListener('click', addPrize);
  addPrize(); // 一等奖默认存在

  // 添加关闭按钮的事件监听器
  const closeButton = document.getElementById('closeModalButton');
  closeButton.addEventListener('click', function () {
    modal.style.visibility = 'hidden' ? 'visible' : 'hidden';
  });

  // 提交表单
  document
    .getElementById('lotteryForm')
    .addEventListener('submit', function (event) {
      event.preventDefault(); // 111
      const jsonData = collectFormData();
      console.log(jsonData);
    });

  return modal;
}

function addPrize() {
  const form = document.getElementById('prizesContainer');
  let prizes = form.querySelectorAll('.prize');
  let prizeCount = prizes.length;

  if (prizeCount >= 3) {
    alert('最多设置三个奖项');
    return;
  }

  console.log(prizeCount);

  const prizeDiv = document.createElement('div');
  prizeDiv.className = 'prize';
  prizeDiv.innerHTML = `
      <div class="prize-label">
        <span class="prize-number">第 ${prizeCount + 1} 等奖每份金额:</span>
        <input type="number" name="prizeAmount${
          prizeCount + 1
        }" class="prize-amount-input" min="0.01" required />
        <select name="prizeCurrency${
          prizeCount + 1
        }" class="prize-currency-select">
            <option value="ETH">ETH</option>
            <option value="USDT">USDT</option>
        </select>
      </div>
      <label>人数:
        <input type="number" name="prizeCount${
          prizeCount + 1
        }" min="1" max="19" class="prize-count-input" required />
      </label>
      <button type="button" class="deletePrize">删除</button>
  `;

  // 更新数据

  const deleteButton = prizeDiv.querySelector('.deletePrize');
  deleteButton.addEventListener('click', function () {
    // 重新获取当前奖项列表以确保长度信息是最新的
    prizes = form.querySelectorAll('.prize');
    if (prizes.length <= 1) {
      alert('至少保留一个奖项');
      return;
    }
    prizeDiv.remove();
    // 再次获取最新的奖项列表以更新UI和逻辑处理
    prizes = form.querySelectorAll('.prize');
    updatePrizeLabels(); // 更新标签确保编号正确
    console.log(prizes.length);
  });

  form.insertBefore(prizeDiv, document.getElementById('addPrizeButton'));

  prizes = form.querySelectorAll('.prize');
  console.log(prizes);
  prizeCount = prizes.length;
  console.log(prizeCount);
}

function updatePrizeLabels() {
  const prizes = document.querySelectorAll('.prize');

  prizes.forEach((prize, index) => {
    const prizeNumberSpan = prize.querySelector('.prize-number');
    if (prizeNumberSpan) {
      prizeNumberSpan.textContent = `第 ${index + 1} 等奖金额:`;
    }
  });
}

// 汇总 json 数据
function collectFormData() {
  const form = document.getElementById('lotteryForm');
  const prizes = form.querySelectorAll('.prize');

  let formData = {
    retweetRequired: form.querySelector('input[name="requireRetweet"]').checked,
    likeRequired: form.querySelector('input[name="requireLike"]').checked,
    prizes: [],
  };

  const deadlineInput = form.querySelector('input[name="deadline"]').value;
  const localDate = new Date(deadlineInput);
  // 计算UTC时间戳
  const deadlineTimestamp =
    Date.UTC(
      localDate.getUTCFullYear(),
      localDate.getUTCMonth(),
      localDate.getUTCDate(),
      localDate.getUTCHours(),
      localDate.getUTCMinutes(),
      localDate.getUTCSeconds()
    ) / 1000;

  formData.deadline = deadlineTimestamp;

  prizes.forEach((prize, index) => {
    let prizeData = {
      amount: prize.querySelector('.prize-amount-input').value,
      currency: prize.querySelector('.prize-currency-select').value,
      count: prize.querySelector('.prize-count-input').value,
    };
    formData.prizes.push(prizeData);
  });

  return JSON.stringify(formData);
}

export default createModal;
