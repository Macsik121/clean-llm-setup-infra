OmniRoute

Проблема: Dashboard-first приложение, нет REST API для настройки провайдеров.

Преимщуество этого pipeline: при сложности, что нет Rest API, и при изменениях его в других версиях, этот pipeline задаёт общие правила по вычислению всех необходимых деталей на странице, что позволяет задавать этот пайплайн вне зависимости от версии.

**helper code:**
1. getElementsByClassName(class: String) -> NodeElement

This function helps find the Elements by just Copying and Pasting their classes through Console F12.

```javascript
function getElementByClassName(fullElementClass, parentEl = document) {
    const rawClasses = fullElementClass.split(" ");
    // const filterChars = [':', '/', '[', ']'];
    const filteredClasses = rawClasses.filter(el => !el.includes(":") && !el.includes("/") && !el.includes("[") && !el.includes("]")); 
    
    console.log(filteredClasses)
    const selector = '.' + filteredClasses.join('.');
    return parentEl.querySelector(selector);
}
/* 

Consider using a regular expression for a string to pass the querySelector restrictions: 

const cleanIdentifierRegex = /^(?![0-9]|--|-[0-9])[a-zA-Z0-9_-]+$/;

cleanIdentifierRegex.test("my-class") // true
console.log(cleanIdentifierRegex.test("1st-place"));  // false

*/
```

## Pipeline:
0. navigate link in the browser: http://localhost:20128/dashboard/provider/kiro
1. Соединения -> + Добавить -> Выбираем одно из 3-х:
    - Учётная запись Google
    - Учётная запись GitHub
2. берём ссылку у элемента "text-xs font-mono text-primary underline break-all max-w-md inline-block"
3. открываем browser в режиме инкогнито
4. заходим в аккаунт(по free LLM instructions)
5. подключение появляется в списке общих. Переименовываем как у нас есть криды от аккаунта, чтобы знать, какое подключение соответствует какому аккаунту.

## Добавление подключения

```javascript
addButton = 
getElementByClassName("inline-flex items-center justify-center gap-2 font-medium transition-all duration-200 cursor-pointer active:scale-[0.99] disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 bg-[image:var(--grad-brand)] text-white shadow-sm hover:brightness-105 h-7 px-3 text-xs rounded-control");

addButton.dispatchEvent(new MouseEvent('click', { bubbles: true, }));

setTimeout(() => {
    const authMethodDiv = getElementByClassName("space-y-3");
    const googleRegistrationDiv = authMethodDiv.childNodes[3]
    const githubRegistrationDiv = authMethodDiv.childNodes[4]
    const authMethodChoice = prompt("Are you choosing google or github account registration?\n 1. Учётная запись Google \n 2. Учётная запись Github. \n По умолчанию выбирается п. 1", 1);
    if (authMethodChoice == 1)
        googleRegistrationDiv.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    else (authMethodChoice == 2)
        githubRegistrationDiv.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    setTimeout(() => {
        regLink = getElementByClassName("text-xs font-mono text-primary underline break-all max-w-md inline-block")
        console.log(regLink.href)
    }, 2000);
}, 100);

```

## После добавления подключения

Общий список подключений -> берём последний блок оттуда(это наше недавнее подключение) -> нажимаем на кнопку изменить -> alert("Вставьте в название почту и пароль аккаунта, чтобы не забыть, от какого аккаунта это подключение. Сохраните изменения(кнопка внизу формы).") -> получаем input имени по ID = nameInput -> nameInput.focus() -> Пользователь вставляет по желанию

Вот код именно для моей текущей версии omniroute. С тем, как меняется dashboard и страница провайдеров, нужно следить за вложенностью childNodes друг в друге. Очевидно, в следующих весриях omniroute это может поменяться. В новой версии нужно с помощью инспектора подбирать вложенность элементов друг в друга.
```javascript
// getting the last connection
connections = getElementByClassName("bg-surface border border-border rounded-card shadow-sm p-6")
conns = connections.childNodes[3].childNodes // all connections div
connection = conns[conns.length - 1] // last connection div

// clicking the button "edit"
editBtn = connection.childNodes[1].childNodes[3].childNodes[1] // last connection edit button
editBtn.dispatchEvent(new MouseEvent('click', { bubbles: true })) // click this element

// name input focusing
changeDialogue = getElementByClassName("relative w-full bg-surface border rounded-card shadow-2xl animate-in fade-in zoom-in-95 duration-200 max-w-md")
setTimeout(() => {
    nameInput = getElementByClassName("w-full py-2 px-3 text-text-main bg-white dark:bg-white/5 border border-black/10 dark:border-white/10 rounded-control placeholder-text-muted/60 focus:ring-1 focus:ring-accent/30 focus:border-accent/50 focus:outline-none transition-all shadow-inner disabled:opacity-50 disabled:cursor-not-allowed text-[16px] sm:text-sm");
    nameInput.focus();
}, 100);
```
