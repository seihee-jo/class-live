// 질문 순서 = 발표자가 넘기는 순서. id는 DB에 저장되므로 강의 중에는 바꾸지 않는다.
// kind: screen(안내 화면) · choice(선택) · scale(1~5) · short(단어) · text(자유 답변)
window.SURVEY = {
  title: '한동대 직무 특강',
  version: '3',   // 질문을 바꾸거나 본 강의 직전에 올리면 학생 폰의 "제출 완료" 기록이 초기화된다
  steps: [
    { id: 'wait', kind: 'screen', label: '시작 전',
      title: 'QR로 접속해 주세요', sub: '모든 답변은 익명이에요. 질문이 열리면 이 화면이 바로 바뀌어요.' },
    { id: 'q1', kind: 'choice', label: '학기',
      title: '지금 몇 학기인가요?',
      options: ['1~2학기', '3~4학기', '5~6학기', '7~8학기', '8학기 초과 · 졸업'] },
    { id: 'q2', kind: 'scale', label: 'SaaS 영업 이해도',
      title: 'IT SaaS 영업, 얼마나 알고 있나요?', min: '처음 들어요', max: '설명할 수 있어요' },
    { id: 'q3', kind: 'short', label: '영업의 이미지',
      title: '"영업" 하면 어떤 이미지가 떠오르나요?',
      hint: '예) 술 영업, 정장 입은 사람들, 말 잘하는 사람들',
      placeholder: '떠오르는 이미지를 짧게', max: 30 },
    { id: 'q4', kind: 'choice', label: '진로 고려',
      title: '영업 관련 직무를 진로로 생각해 본 적 있나요?',
      options: ['있어요', '고민 중이에요', '아직 없어요'] },
    // multi: 여러 개 선택. 장표 Part 1~4 순서와 맞춘 보기라, 결과를 보고 어느 Part를 깊게 말할지 정한다.
    { id: 'q5', kind: 'multi', label: '기대',
      title: '오늘 가장 기대하는 것은? (여러 개 선택)',
      options: [
        '영업 직무로 커리어를 시작하게 된 계기',
        '현재 B2B SaaS IT 영업 시장 상황',
        '실제 영업이 진행되는 과정 (고객 발굴부터 계약까지)',
        '영업 관련 직무 종류와 하루 일과',
        '영업 직무에 필요한 역량과 자격',
      ] },
    { id: 'q6', kind: 'text', label: '궁금한 것',
      title: '평소 가장 궁금했던 것', placeholder: '영업, SaaS, 진로, 회사 생활 무엇이든', max: 200 },
    { id: 'pause', kind: 'screen', label: '세션 진행 중',
      title: '세션을 시작할게요', sub: '세션 끝에 질문이 다시 열려요. 이 창은 열어 두셔도 돼요.' },
    { id: 'q7', kind: 'text', label: '액션 아이템',
      title: '오늘 돌아가서 실천할 액션 아이템 1가지',
      hint: '예) 가고 싶은 회사나 한동대 선배님께 커피챗 요청하기\n예) 뭐라도 만들어서 팔아 보기 (웹사이트를 만들어 내 시간을 팔고, 프리랜서로 외주 작업해 보기 등)',
      placeholder: '나는 돌아가서', max: 200 },
    // coffee: 연락처를 받는 비공개 신청. answers가 아니라 coffee_chats 표에 저장되고,
    // 발표 화면에는 신청 수만 보인다. 내용은 results.html(발표자 키)에서만 본다.
    { id: 'coffee', kind: 'coffee', label: '커피챗 신청',
      title: '[선택] AB180 재직자(영업 직무)와 커피챗을 하고 싶으시다면 정보를 남겨주세요.',
      hint: '남기지 않아도 괜찮아요. 남겨 주신 정보는 조세희만 볼 수 있어요.',
      jobOptions: ['지금 취업을 준비하고 있어요', '1년 안에 고려하고 있어요', '아직은 탐색 중이에요'] },
    { id: 'end', kind: 'screen', label: '', title: '감사합니다.', sub: '' },
  ],
};
