const SUPABASE_URL='https://gkkxwhopjytagkoqnnrn.supabase.co';
const SUPABASE_PUBLISHABLE_KEY='sb_publishable_zoU71fWjrIFyT7OctEzRGg_-43FjQy-';
const $=id=>document.getElementById(id);
let db,user,profile,themes=[],shared=[],personal=[],wishes=[],authNotice='';
const ready=!SUPABASE_URL.includes('YOUR_')&&!SUPABASE_PUBLISHABLE_KEY.includes('YOUR_');

if(!ready||!window.supabase){$('setup').classList.remove('hidden');}
else{db=window.supabase.createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY);init();}

function usernameEmail(value){
  const v=value.trim().toLowerCase();
  return v.includes('@')?v:`${v}@users.escape-log.invalid`;
}
function showAuth(msg=''){
  $('auth').classList.remove('hidden');$('app').classList.add('hidden');$('logout').classList.add('hidden');
  if(msg)authNotice=msg;
  $('authMsg').textContent=msg||authNotice||'';
}
async function init(){
  const {data:{session}}=await db.auth.getSession();
  if(session)await enter(session.user);else showAuth('');
  db.auth.onAuthStateChange((event,session)=>{
    setTimeout(()=>{
      if(session)enter(session.user);
      else{user=null;profile=null;showAuth(authNotice);}
    },0);
  });
}
async function enter(u){
  user=u;
  const {data:p,error}=await db.from('profiles').select('nickname,is_approved').eq('id',u.id).maybeSingle();
  if(error){await db.auth.signOut();showAuth('프로필 조회 오류: '+error.message);return;}
  if(!p){await db.auth.signOut();showAuth('프로필 정보가 없습니다. 관리자에게 문의하세요.');return;}
  if(!p.is_approved){
    authNotice='가입 신청이 접수됐습니다. 관리자의 승인 후 로그인할 수 있습니다.';
    await db.auth.signOut();showAuth(authNotice);return;
  }
  authNotice='';profile=p;
  $('auth').classList.add('hidden');$('app').classList.remove('hidden');$('logout').classList.remove('hidden');
  updateWelcome();await reload();
}
function updateWelcome(){$('welcome').textContent=(profile?.nickname||user?.email||'멤버')+'님의 방탈출 기록';}

$('login').addEventListener('submit',async e=>{
  e.preventDefault();authNotice='';$('authMsg').textContent='로그인 중...';
  const {error}=await db.auth.signInWithPassword({email:usernameEmail($('loginId').value),password:$('password').value});
  if(error){authNotice='로그인 실패: '+error.message;$('authMsg').textContent=authNotice;}
});
$('signup').addEventListener('submit',async e=>{
  e.preventDefault();authNotice='';
  const username=$('signupId').value.trim().toLowerCase(),nickname=$('signupNickname').value.trim(),password=$('signupPassword').value;
  if(!/^[a-z0-9._-]{3,30}$/.test(username)){ $('authMsg').textContent='아이디는 영문 소문자, 숫자, 점(.), 밑줄(_), 하이픈(-)으로 3~30자 입력하세요.';return; }
  if(!nickname){$('authMsg').textContent='닉네임을 입력하세요.';return;}
  $('authMsg').textContent='가입 신청 중...';
  const {data,error}=await db.auth.signUp({email:usernameEmail(username),password,options:{data:{nickname,username}}});
  if(error){$('authMsg').textContent='가입 실패: '+error.message;return;}
  if(data?.session)await db.auth.signOut();
  authNotice='가입 신청이 완료됐습니다. 관리자의 승인 후 로그인할 수 있습니다.';
  $('authMsg').textContent=authNotice;$('signupPassword').value='';
});
$('logout').onclick=async()=>{authNotice='';await db.auth.signOut();showAuth('');};

$('changeNickname').addEventListener('click',async()=>{
  if(!user||!profile)return;
  const next=prompt('변경할 닉네임을 입력하세요.',profile.nickname||'');
  if(next===null)return;
  const nickname=next.trim();
  if(!nickname||nickname.length>40){alert('닉네임은 1~40자로 입력하세요.');return;}
  const {data,error}=await db.from('profiles').update({nickname}).eq('id',user.id).select('nickname').single();
  if(error){alert('닉네임 변경 실패: '+error.message);return;}
  profile.nickname=data.nickname;updateWelcome();alert('닉네임을 변경했습니다.');
});

async function reload(){await Promise.all([loadThemes(),loadShared(),loadPersonal(),loadWishes()]);}
async function loadThemes(){
 const {data,error}=await db.from('themes').select('*').order('theme_name');if(error)return alert(error.message);
 themes=data||[];renderThemes();$('themeId').innerHTML='<option value="">직접 입력</option>'+themes.map(t=>`<option value="${t.id}">${esc(t.theme_name)}${t.store_name?' · '+esc(t.store_name):''}</option>`).join('');
}
async function loadShared(){
 const {data,error}=await db.from('shared_play_records').select('*,themes(theme_name,store_name,region)').order('played_at',{ascending:false});if(error)return alert(error.message);
 shared=data||[];renderList('sharedList',shared,'shared',$('sharedSearch').value);
}
async function loadPersonal(){
 const {data,error}=await db.from('personal_play_records').select('*,themes(theme_name,store_name,region)').order('played_at',{ascending:false});if(error)return alert(error.message);
 personal=data||[];renderList('personalList',personal,'personal',$('personalSearch').value);
}
async function loadWishes(){
 const {data,error}=await db.from('wishlist_items').select('*,themes(theme_name,store_name,region)').order('created_at',{ascending:false});if(error)return alert(error.message);
 wishes=data||[];renderList('wishList',wishes,'wish',$('wishSearch').value);
}
function esc(s=''){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function title(r){return r.themes?.theme_name||r.theme_name||'테마';}
function renderList(target,rows,kind,q=''){
 q=q.toLowerCase();
 const list=rows.filter(r=>(title(r)+' '+(r.themes?.store_name||r.store_name||'')+' '+(r.review||r.note||'')).toLowerCase().includes(q));
 $(target).innerHTML=list.length?list.map(r=>`<article class="item"><b>${esc(title(r))}</b><p class="muted">${esc(r.themes?.store_name||r.store_name||'매장 미입력')} · ${esc(r.played_at||({want:'가고 싶음',planned:'예약/계획함',played:'플레이 완료'}[r.status]||''))}</p><p>${esc(r.review||r.note||'')}</p>${kind==='personal'?`<small>${r.visibility==='shared'?'공동 공개':'나만 보기'}</small>`:''}<p><button data-edit="${r.id}" data-kind="${kind}">수정</button><button data-delete="${r.id}" data-kind="${kind}">삭제</button></p></article>`).join(''):'<p class="muted">기록이 없습니다.</p>';
}
function renderThemes(){
 const q=$('themeSearch').value.toLowerCase(),list=themes.filter(t=>(t.theme_name+' '+(t.store_name||'')+' '+(t.region||'')).toLowerCase().includes(q));
 $('themeList').innerHTML=list.length?list.map(t=>`<article class="item"><b>${esc(t.theme_name)}</b><p class="muted">${esc(t.store_name||'매장 미입력')} · ${esc(t.region||'지역 미입력')}</p><button data-edit="${t.id}" data-kind="theme">수정</button><button data-delete="${t.id}" data-kind="theme">삭제</button></article>`).join(''):'<p class="muted">등록된 테마가 없습니다.</p>';
}
document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>{document.querySelectorAll('.view').forEach(v=>v.classList.add('hidden'));$(b.dataset.view).classList.remove('hidden');});
document.querySelectorAll('[data-add]').forEach(b=>b.onclick=()=>openEditor(b.dataset.add));
$('cancel').onclick=()=>$('editor').close();
$('themeId').onchange=()=>{const t=themes.find(t=>t.id===$('themeId').value);if(t){$('themeName').value=t.theme_name;$('storeName').value=t.store_name||'';$('region').value=t.region||'';}};
function openEditor(kind,row=null){
 $('editForm').reset();$('kind').value=kind;$('itemId').value=row?.id||'';
 $('editTitle').textContent=({shared:'공동 플레이 기록',personal:'개인 플레이 기록',wish:'공동 위시리스트',theme:'테마 등록'})[kind];
 $('publicLabel').classList.toggle('hidden',kind!=='personal');$('statusLabel').classList.toggle('hidden',kind!=='wish');
 ['date','result','remaining'].forEach(id=>$(id).parentElement.classList.toggle('hidden',kind==='theme'||kind==='wish'));
 $('note').parentElement.classList.toggle('hidden',false);$('themeId').classList.toggle('hidden',kind==='theme');
 if(row){
  $('themeId').value=row.theme_id||'';$('themeName').value=row.themes?.theme_name||row.theme_name||'';
  $('storeName').value=row.themes?.store_name||row.store_name||'';$('region').value=row.themes?.region||row.region||'';
  $('date').value=row.played_at||'';$('result').value=row.result||'unknown';$('remaining').value=row.remaining_minutes??'';
  $('note').value=row.review||row.note||'';$('public').checked=row.visibility==='shared';$('status').value=row.status||'want';
 }else{$('date').value=new Date().toISOString().slice(0,10);$('public').checked=false;}
 $('editor').showModal();
}
document.addEventListener('click',e=>{
 const ed=e.target.closest('[data-edit]'),del=e.target.closest('[data-delete]');
 if(ed){const kind=ed.dataset.kind,rows=({shared,personal,wish:wishes,theme:themes})[kind];openEditor(kind,rows.find(r=>r.id===ed.dataset.edit));}
 if(del){const kind=del.dataset.kind,id=del.dataset.delete;if(confirm('삭제할까요?')){const table=({shared:'shared_play_records',personal:'personal_play_records',wish:'wishlist_items',theme:'themes'})[kind];db.from(table).delete().eq('id',id).then(({error})=>error?alert(error.message):reload());}}
});
$('editForm').addEventListener('submit',async e=>{
 e.preventDefault();const kind=$('kind').value,id=$('itemId').value;let themeId=$('themeId').value;const name=$('themeName').value.trim();if(!name)return;
 try{
  if(kind==='theme'){
   const payload={theme_name:name,store_name:$('storeName').value||null,region:$('region').value||null,created_by:user.id};
   const q=id?db.from('themes').update(payload).eq('id',id):db.from('themes').insert(payload);const {error}=await q;if(error)throw error;
  }else{
   if(!themeId){
    const {data:found}=await db.from('themes').select('id').ilike('theme_name',name).limit(1).maybeSingle();
    if(found)themeId=found.id;
    else{const {data:created,error}=await db.from('themes').insert({theme_name:name,store_name:$('storeName').value||null,region:$('region').value||null,created_by:user.id}).select('id').single();if(error)throw error;themeId=created.id;}
   }
   let table,payload;
   if(kind==='wish'){table='wishlist_items';payload={theme_id:themeId,note:$('note').value||null,status:$('status').value,added_by:user.id};}
   else{table=kind==='shared'?'shared_play_records':'personal_play_records';payload={theme_id:themeId,played_at:$('date').value||null,result:$('result').value,remaining_minutes:$('remaining').value===''?null:Number($('remaining').value),review:$('note').value||null};if(kind==='shared')payload.created_by=user.id;else{payload.user_id=user.id;payload.visibility=$('public').checked?'shared':'private';}}
   const q=id?db.from(table).update(payload).eq('id',id):db.from(table).insert(payload);const {error}=await q;if(error)throw error;
  }
  $('editor').close();await reload();
 }catch(err){alert('저장 실패: '+err.message);}
});
$('sharedSearch').oninput=()=>renderList('sharedList',shared,'shared',$('sharedSearch').value);
$('personalSearch').oninput=()=>renderList('personalList',personal,'personal',$('personalSearch').value);
$('wishSearch').oninput=()=>renderList('wishList',wishes,'wish',$('wishSearch').value);
$('themeSearch').oninput=renderThemes;
