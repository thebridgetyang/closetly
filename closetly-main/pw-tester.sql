CALL sp_add_user('alex', 'hello');
CALL sp_add_user('bowie', 'goodbye');

SELECT authenticate ('chaka', 'hello');
SELECT authenticate ('alex', 'goodbye');
SELECT authenticate ('alex', 'hello');
SELECT authenticate ('alex', 'HELLO');
SELECT authenticate ('bowie', 'goodbye');

CALL sp_change_password('alex', 'greetings');

SELECT authenticate('alex', 'hello');
SELECT authenticate('alex', 'greetings');
SELECT authenticate('bowie', 'greetings');