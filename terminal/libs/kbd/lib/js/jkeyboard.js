
// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
; (function ($, window, document, undefined) {

    // undefined is used here as the undefined global variable in ECMAScript 3 is
    // mutable (ie. it can be changed by someone else). undefined isn't really being
    // passed in so we can ensure the value of it is truly undefined. In ES5, undefined
    // can no longer be modified.

    // window and document are passed through as local variable rather than global
    // as this (slightly) quickens the resolution process and can be more efficiently
    // minified (especially when both are regularly referenced in your plugin).

    // Create the defaults once
    var pluginName = "jkeyboard",
        defaults = {
            layout: "english",
            selectable: [],
            input: $('#input'),

            // от двойных нажатий. Если checkTimeout, то проверяется:
            // если последний введенный символ такой же как и текущий
            // и введен меньше чем setTimeout милисекунд назад то не печатаем его
            checkTimeout: true,
            setTimeout: 150,
            // если true - то первая буква каждого слова будет заглавной
            firstUpper: false,
            customLayouts: {
                selectable: []
            },
        };


    var function_keys = {
        backspace: {
            text: '&nbsp;',
        },
        return: {
            text: 'Enter'
        },
        shift: {
            text: '&nbsp;'
        },
        space: {
            text: '&nbsp;'
        },
        numeric_switch: {
            text: '123',
            command: function () {
                this.createKeyboard('numeric');
                this.events();
                var input=this.settings.input;
                $(input).trigger('focus');
            }
        },
        layout_switch: {
            text: '&nbsp;',
            command: function () {
                var l = this.toggleLayout();
                this.createKeyboard(l);
                this.events();
                var input=this.settings.input;
                $(input).trigger('focus');
            }
        },
        character_switch: {
            text: 'ABC',
            command: function () {
                this.createKeyboard(layout);
                this.events();
                var input=this.settings.input;
                $(input).trigger('focus');
            }
        },
        symbol_switch: {
            text: '#+=',
            command: function () {
                this.createKeyboard('symbolic');
                this.events();
                var input=this.settings.input;
                $(input).trigger('focus');
            }
        },
        kclose: {
            text: '',
            command: function() {
                $(this.element).empty();
            }
        }
    };


    var layouts = {
        azeri: [
            ['q', 'ü', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'ö', 'ğ'],
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'ı', 'ə'],
            ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'ç', 'ş', 'backspace'],
            ['numeric_switch', 'layout_switch', 'space', 'return']
        ],
        english: [
            ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',],
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',],
            ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace'],
            ['numeric_switch', 'layout_switch', 'space', 'return']
        ],
        email: [
            ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',],
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',],
            ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace'],
            ['numeric_switch', '@', 'space', '.']
        ],
        email5: [
            ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',],
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',],
            ['shift', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace'],
            ['numeric_switch', '@', 'space', 'kclose']
        ],

        german: [
            ['q', 'w', 'e', 'r', 't', 'z', 'u', 'i', 'o', 'p','ü','ß'],
            ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l','ö','ä'],
            ['shift', 'y', 'x', 'c', 'v', 'b', 'n', 'm', 'backspace'],
            ['numeric_switch', 'layout_switch', 'space', 'return']
        ],
        russian: [
            ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х'],
            ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
            ['shift', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'backspace'],
            ['numeric_switch', 'layout_switch', 'space', 'return']
        ],
		russian1: [
            ['ё','й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х'],
            ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э','ъ'],
            ['shift', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'backspace'],
            ['numeric_switch', 'space','.',',','-']
        ],
        russian2: [
            ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х'],
            ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
            ['shift', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'backspace'],
            ['kclose','numeric_switch', 'space']
        ],
        russianOnly: [
            ['ё','й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х'],
            ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э', 'ъ'],
            ['shift', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', 'backspace'],
            ['-', 'space']
        ],
        numeric: [
            ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
            ['-', '/', ':', ';', '(', ')', '$', '&', '@', '"'],
            ['symbol_switch', '.', ',', '?', '!', "'", 'backspace'],
            ['character_switch', 'space', 'return'],
        ],
        numbers_only: [
            ['1', '2', '3',],
            ['4', '5', '6',],
            ['7', '8', '9',],
            ['0', 'return', 'backspace'],
        ],
		numbers_only1: [
            ['1', '2', '3',],
            ['4', '5', '6',],
            ['7', '8', '9',],
            ['0', 'backspace'],
        ],
        numbers_only2: [
            ['1', '2', '3',],
            ['4', '5', '6',],
            ['7', '8', '9',],
            ['kclose','0', 'backspace'],
        ],
        symbolic: [
            ['[', ']', '{', '}', '#', '%', '^', '*', '+', '='],
            ['_', '\\', '|', '~', '<', '>'],
            ['numeric_switch', '.', ',', '?', '!', "'", 'backspace'],
            ['character_switch', 'space', 'return'],

        ]
    }

    var shift = false, capslock = false, layout = 'english', layout_id = 0,
        prevKey = '', prevTimestamp=0;

    // The actual plugin constructor
    function Plugin(element, options) {
        this.element = element;
        // jQuery has an extend method which merges the contents of two or
        // more objects, storing the result in the first object. The first object
        // is generally empty as we don't want to alter the default options for
        // future instances of the plugin
        this.settings = $.extend({}, defaults, options);
        // Extend & Merge the cusom layouts
        layouts = $.extend(true, {}, this.settings.customLayouts, layouts);
        if (Array.isArray(this.settings.customLayouts.selectable)) {
            $.merge(this.settings.selectable, this.settings.customLayouts.selectable);
        }
        this._defaults = defaults;
        this._name = pluginName;
        this.init();
    }

    Plugin.prototype = {
        init: function () {
            layout = this.settings.layout;
            this.createKeyboard(layout);
            this.events();
        },

        setInput: function (newInputField) {
            this.settings.input = newInputField;
        },

        createKeyboard: function (layout) {
            shift = false;
            capslock = false;

            var keyboard_container = $('<ul/>').addClass('jkeyboard'),
                me = this;

            layouts[layout].forEach(function (line, index) {
                var line_container = $('<li/>').addClass('jline');
                line_container.append(me.createLine(line));
                keyboard_container.append(line_container);
            });

            $(this.element).html('').append(keyboard_container);
        },

        createLine: function (line) {
            var line_container = $('<ul/>');

            line.forEach(function (key, index) {
                var key_container = $('<li/>').addClass('jkey').data('command', key);

                if (function_keys[key]) {
                    key_container.addClass(key).html(function_keys[key].text);
                }
                else {
                    key_container.addClass('letter').html(key);
                }

                line_container.append(key_container);
            })

            return line_container;
        },

        events: function () {
            var letters = $(this.element).find('.letter'),
                shift_key = $(this.element).find('.shift'),
                space_key = $(this.element).find('.space'),
                backspace_key = $(this.element).find('.backspace'),
                return_key = $(this.element).find('.return'),
                close_key = $(this.element).find('.kclose'),
                me = this,
                input = me.settings.input,
                fkeys = Object.keys(function_keys).map(function (k) {
                    return '.' + k;
                }).join(',');

            letters.on('click', function () {
                me.type((shift || capslock) ? $(this).text().toUpperCase() : $(this).text());
                prevTimestamp= (new Date).getTime();
                me.settings.input.parents('form').submit();
            });

            space_key.on('click', function () {
                me.type(' ');
                prevTimestamp= (new Date).getTime();
                prevKey = ' ';
                me.settings.input.parents('form').submit();
            });

            return_key.on('click', function () {
                me.type("\n");
                prevKey = '';
                prevTimestamp= (new Date).getTime();
                me.settings.input.parents('form').submit();
            });

            backspace_key.on('click', function () {
                me.backspace();
                prevKey = '';
                prevTimestamp= (new Date).getTime();
            });

            shift_key.on('click', function () {
                if (shift) {
                    me.toggleShiftOff();
                    capslock=false;
                } else {
                    me.toggleShiftOn();
                }
                prevKey = '';
                prevTimestamp= (new Date).getTime();
                $(input).trigger('focus');
            }).on('dblclick', function () {
                capslock = true;
                me.toggleShiftOn();
                prevKey = '';
                prevTimestamp= (new Date).getTime();
                $(input).trigger('focus');
            });
            close_key.on('click', function(){
                //me.close();
            });

            $(fkeys).on('click', function () {
                var command = function_keys[$(this).data('command')].command;
                if (!command) return;
                prevKey = '';
                prevTimestamp= (new Date).getTime();
                command.call(me);
            });
        },

        type: function (key) {
            function ucFirst(str) {
                // только пустая строка в логическом контексте даст false
                if (!str) return str;

                return str[0].toUpperCase() + str.slice(1);
            }
            var input = this.settings.input,
                val = input.val(),
                input_node = input.get(0),
                start = input_node.selectionStart,
                end = input_node.selectionEnd,
                max_length = $(input).attr("maxlength"),
                nowTimestamp = (new Date).getTime();
            //console.log(prevTimestamp, nowTimestamp,nowTimestamp-prevTimestamp, prevKey,key);
            if (this.settings.checkTimeout && nowTimestamp-prevTimestamp<this.settings.setTimeout && key==prevKey)
            {
                input.trigger('focus');
                return false;
            }
            if (start == end && end == val.length) {
                if (!max_length || val.length < max_length) {
                    input.val(val + key);
                    prevKey=key;
                }
            } else {
                var new_string = this.insertToString(start, end, val, key);
                input.val(new_string);
                start++;
                end = start;
                input_node.setSelectionRange(start, end);
                prevKey=key;
            }
            if (this.settings.firstUpper) {
                var str=input.val(), ch=' ';
                if (str.length > 0) {
                    str=ucFirst(str);
                    for (let i = 0; i < str.length-1; i++) {
                        if (str[i]==' ' || str[i]=='-'){
                            ch=ucFirst(str[i+1]);
                            str=str.substr(0,i+1)+ch+str.substr(i+2);
                        }
                    }
                    input.val(str);
                }
            }
            input.trigger('focus');

            if (shift && !capslock) {
                this.toggleShiftOff();
            }
        },

        backspace: function () {
            function symbolOfMask(aPos,aMask){
                var i=aPos;
                while (i>-1) {
                    if (aMask[i]=='9' || aMask[i]=='*' || aMask[i]=='a') {
                        return i;
                    } else {
                        i--;
                    }
                }
                return false;
            }
            var input = this.settings.input,
                input_node = input.get(0),
                position_start = input_node.selectionStart-1,
                position_end = input_node.selectionEnd-1,
                maskOfInput = $(input_node).attr("data-mask-string"),
                placeholdr = $(input_node).attr("data-mask-placeholder"),
                str= input.val();

            if (position_start==position_end){
                if (position_end==-1) {
                    $(input).trigger('focus');
                    return false;
                }
                //если к input-у применена маска (из maskedinput)
                if (maskOfInput){
                    //проверяем, является ли стираемый символ нестираемым из маски
                    //и находим первый стираемый
                    var fSymMask=symbolOfMask(position_start,maskOfInput);
                    if (fSymMask || fSymMask===0){
                        //заменяем стираемый символ placeholder-ом
                        str = str.substr(0, fSymMask) + placeholdr + str.substr(fSymMask + 1)+'';
                    }
                } else {
                    str = str.substr(0, position_start) + '' + str.substr(position_end + 1);
                }
            } else {
                str = str.substr(0, position_start+1) + '' + str.substr(position_end + 1);
                position_start=position_start+1;
            }
            $(input).val(str);
            input_node.selectionStart=position_start;
            input_node.selectionEnd=position_start;
            $(input).trigger('focus');
        },

        toggleShiftOn: function () {
            var letters = $(this.element).find('.letter'),
                shift_key = $(this.element).find('.shift');

            letters.addClass('uppercase');
            shift_key.addClass('active')
            shift = true;
        },

        toggleShiftOff: function () {
            var letters = $(this.element).find('.letter'),
                shift_key = $(this.element).find('.shift');

            letters.removeClass('uppercase');
            shift_key.removeClass('active');
            shift = false;
        },

        toggleLayout: function () {
            layout_id = layout_id || 0;
            var plain_layouts = this.settings.selectable;
            layout_id++;

            var current_id = layout_id % plain_layouts.length;
            return plain_layouts[current_id];
        },

        insertToString: function (start, end, string, insert_string) {
            return string.substring(0, start) + insert_string + string.substring(end, string.length);
        },
        close: function(){
            $(this.element).empty();
        }
    };


    var methods = {
        init: function(options) {
            if (!this.data("plugin_" + pluginName)) {
                this.data("plugin_" + pluginName, new Plugin(this, options));
            }
        },
        setInput: function(content) {
            this.data("plugin_" + pluginName).setInput($(content));
        },
        setLayout: function(layoutname) {
            // change layout if it is not match current
            object = this.data("plugin_" + pluginName);
            if (typeof(layouts[layoutname]) !== 'undefined' && object.settings.layout != layoutname) {
                object.settings.layout = layoutname;
                object.createKeyboard(layoutname);
                object.events();
            };
        },
    };

    $.fn[pluginName] = function (methodOrOptions) {
        if (methods[methodOrOptions]) {
            return methods[methodOrOptions].apply(this.first(), Array.prototype.slice.call( arguments, 1));
        } else if (typeof methodOrOptions === 'object' || ! methodOrOptions) {
            // Default to "init"
            return methods.init.apply(this.first(), arguments);
        } else {
            $.error('Method ' +  methodOrOptions + ' does not exist on jQuery.jkeyboard');
        }
    };

})(jQuery, window, document);
