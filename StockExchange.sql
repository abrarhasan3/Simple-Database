drop TRIGGER update_date_users;
drop TRIGGER check_buy_sell;
drop procedure add_users;
drop procedure add_stock_exchange;
drop procedure add_offer_to_sell;
drop procedure add_yearly_revenue;
drop table owned_stock;
drop table buy_sell;
drop table offer_to_sell;
drop table yearly_revenue;
drop table Stock_Exchange;
drop table users;
drop table company_stock;


create table Stock_Exchange(
	exchange_id varchar(20) not null,
	exchange_name varchar(40),
	opening_time varchar(10) DEFAULT '10:00 AM',--USED DEFAULT
	closing_time varchar(10));
-- adding Primary Key
alter table Stock_Exchange ADD PRIMARY KEY (exchange_id);

create table users(
	user_id varchar(20) not null,	
	ac_no number(20),
	balance number(20,2) CHECK (balance>0),--USED CHECK 
	extra varchar(12),
	reg_date Date,
	primary key(user_id));
-- ADDING NEW COLUMN
Alter table users ADD name varchar(20);
-- Drop A column
Alter table users drop COLUMN extra;

create table company_stock(
	company_id varchar(20) NOT NULL,
	company_name varchar(20),
	PRIMARY KEY (company_id));

create table offer_to_sell(
	exchange_id varchar(20) NOT NULL,
	company_id varchar(20) NOT NULL,
	Price varchar(20),
	volume number(10),
	PRIMARY KEY (exchange_id, company_id),
	foreign key (company_id) REFERENCES company_stock (company_id) on DELETE CASCADE,
	foreign key (exchange_id) REFERENCES stock_exchange (exchange_id) 
	on DELETE CASCADE);
-- MODIFY PRICE COLUMN
Alter table offer_to_sell MODIFY Price number(10,3);

create table buy_sell(
	user_id varchar(20) NOT NULL,
	exchange_id varchar(20) NOT NULL,
	primary key (user_id,exchange_id),
	foreign key (exchange_id) REFERENCES stock_exchange (exchange_id) 
	on DELETE CASCADE);
--ADDED FOREIGN KEY
Alter table buy_sell ADD foreign key (user_id) REFERENCES users (user_id) on DELETE CASCADE;

create table yearly_revenue(
	amount number(20,3),
	user_id varchar(20) NOT NULL,
	company_id varchar(20)NOT NULL,
	exchange_id varchar(20) NOT NULL,
	PRIMARY KEY (user_id, company_id,exchange_id),
	foreign key (user_id) REFERENCES users (user_id) on DELETE CASCADE,
	foreign key (company_id) REFERENCES company_stock (company_id) 
	on DELETE CASCADE,
	foreign key (exchange_id) REFERENCES stock_exchange(exchange_id) on DELETE CASCADE);

Create Table Owned_stock(
	company_name varchar(20),
	quantity number(20),
	buy_price number(20),
	user_id varchar(20) NOT NULL,
	exchange_id varchar(20) NOT NULL,
	company_id varchar(20) NOT NULL,
	PRIMARY KEY (user_id, company_id,exchange_id),
	foreign key (user_id) REFERENCES users (user_id) on DELETE CASCADE,
	foreign key (company_id) REFERENCES company_stock (company_id) 
	on DELETE CASCADE,
	foreign key (exchange_id) REFERENCES stock_exchange (exchange_id) 
	on DELETE CASCADE);


CREATE OR REPLACE PROCEDURE add_users(
user_id1 users.user_id%TYPE,
name1 users.name%type,
ac_no1 users.ac_no%type,
balance1 users.balance%type) IS
BEGIN
	INSERT INTO USERS (user_id,name,ac_no,balance) 
	values (user_id1,name1,ac_no1,balance1);	
END add_users;
/
SHOW ERROR

CREATE OR REPLACE PROCEDURE add_stock_Exchange(
exchange_id1 stock_exchange.exchange_id%TYPE,
ex_name stock_exchange.exchange_name%type,
open1 stock_exchange.opening_time%TYPE,
close1 stock_exchange.closing_time%TYPE) IS
BEGIN
	INSERT INTO stock_exchange (exchange_id ,exchange_name,opening_time,CLOSING_TIME) 
	values (exchange_id1,ex_name,open1,close1);
	
END add_stock_Exchange;
/

create or replace procedure add_company_stock(
id company_stock.company_id%type,
name company_stock.company_name%type) IS
BEGIN
	INSERT into company_stock(company_id,company_name)
	values (id,name);
END add_company_stock;
/

create or replace procedure add_owned_stock(
name owned_stock.company_name%type,
quan owned_stock.quantity%type,
buyPrice owned_stock.buy_price%type,
uid owned_stock.user_id%type,
eid owned_stock.exchange_id%type,
cid owned_stock.company_id%type) IS
BEGIN
	Insert into OWNED_STOCK (company_name,quantity,buy_price,user_id,company_id,exchange_id)
	values (name,quan,buyPrice,uid,cid,eid);
END add_owned_stock;
/

CREATE or REPLACE PROCEDURE add_offer_to_sell(
eid offer_to_sell.exchange_id%type,
cid offer_to_sell.company_id%type,
price1 offer_to_sell.Price%type,
volume1 offer_to_sell.volume%type) IS
BEGIN
	INSERT into offer_to_sell (exchange_id,company_id,Price,volume)
	values(eid,cid,price1,volume1);


END add_offer_to_sell;
/


SET SERVEROUTPUT ON
create or replace procedure add_yearly_revenue(	
	am1 yearly_revenue.amount%type,
	uid users.user_id%type,
	cid company_stock.company_id%type,
	eid stock_exchange.exchange_id%type) IS
	--<ADDED LOCAL VARIABLE TO PL/SQL PROCEDURE>
	c number;
BEGIN
--<THIS IS FOR CHECKING IF THE USER HAS STOCK FROM THIS COMPANY>--
	select count(1) into c from owned_stock where cid=company_id and eid=owned_stock.exchange_id 
		and uid=owned_stock.user_id;
	if (c=1) then
		INSERT into yearly_revenue(amount,user_id,company_id,exchange_id)
		values(am1,uid,cid,eid);
	else
		RAISE_APPLICATION_ERROR(-122,'User does not have stock');
	end if;
END add_yearly_revenue;
/

--THIS TRIGEGR WILL AUTOMATICALLY ADD DATA TO buy_sell table when someone buys/sells stocks;
CREATE OR REPLACE TRIGGER check_buy_sell BEFORE INSERT OR UPDATE ON
owned_stock
FOR EACH ROW
DECLARE
c number;
BEGIN
	select count(1) into c from buy_sell 
		where :new.user_id=buy_sell.user_id and :new.exchange_id=buy_sell.exchange_id;
	if(c=0) then
	INSERT INTO buy_sell(user_id,exchange_id) values (:new.user_id,:new.exchange_id);
	end if;
END;
/


-- Automatically Insert The Register Date in User Table
create or REPLACE TRIGGER update_date_users BEFORE INSERT on users
	FOR EACH ROW
DECLARE
	var users.reg_date%type;
BEGIN
	select sysdate into var from dual;
	:new.reg_date:=var;
END;
/	

--THIS FUNCTION SHOWS THE YEARLY REVENUE OF AN USER
CREATE OR REPLACE FUNCTION show_revenue
(uid yearly_revenue.user_id%type)
RETURN yearly_revenue.amount%type IS
ret_value yearly_revenue.amount%type;
BEGIN
	select sum(amount) into ret_value 
	from yearly_revenue where yearly_revenue.user_id=uid;
	RETURN ret_value;
END show_revenue;
/

--This Procedure Returns The Amount Of Profit OR Loss Of an User against His stock
SET SERVEROUTPUT ON
create or REPLACE PROCEDURE calculate_profit_loss
	(
	quan owned_stock.quantity%type,
	uid owned_stock.user_id%type,
	cid owned_stock.company_id%type,
	eid owned_stock.exchange_id%type)IS
	cur_price offer_to_sell.Price%type;
	b_price owned_stock.buy_price%type;
	q1 owned_stock.quantity%type; 
BEGIN
	select price into cur_price from offer_to_sell
	where company_id=cid and exchange_id=eid;

	select buy_price,quantity into b_price,q1 from owned_stock
	where user_id=uid and company_id=cid and exchange_id=eid;

	if b_price>cur_price then
		DBMS_OUTPUT.PUT('LOSS: ');
		DBMS_OUTPUT.PUT_LINE(quan*b_price-quan*cur_price);
	elsif b_price<cur_price then
		DBMS_OUTPUT.PUT_LINE(b_price);
		DBMS_OUTPUT.PUT_LINE(cur_price);
		DBMS_OUTPUT.PUT('PROFIT :');
		DBMS_OUTPUT.PUT_LINE(quan*cur_price-quan*b_price);
	else
		DBMS_OUTPUT.PUT_LINE('No profit or Loss');
	end if;
END calculate_profit_loss;
/


BEGIN

add_users('U-24','Abrar',1807024,10000000.25);
add_users('U-98','Ashfaq',1807098,100234.25);
add_users('U-21','Shoumya',1807021, 123451.54);
add_users('U-3', 'Rupok',1807003,54102.75);
add_users('U-29','Lira', 1807029,500000.29);
add_users('U-118','Mou', 1807118,525000.65);
add_users('U-70','Nafis', 1801070,9401011.65);
add_users('U-73','Sifat', 1801073,876301.65);
add_users('U-20','Sadman', 1807020,606301.65);



add_stock_exchange('101','DSE','10:00 AM','1:00 PM');
add_stock_exchange('102','CHITTOGONG Stock Exchange','11:00 AM','2:00 PM');
add_stock_exchange('103','NEWYORK Stock Exchange','11:00 AM','2:00 PM');
add_stock_exchange('104','London Stock Exchange','11:00 AM','2:00 PM');
add_stock_exchange('105','National Stock Exchange of INDIA','12:00 AM','4:00 PM');
add_stock_exchange('106','Colombo Stock Exchange','10:05 AM','10:05 AM');


add_company_stock('C-1','Exim Bank');
add_company_stock('C-2','BRAC Bank');
add_company_stock('C-3','TESLA');
add_company_stock('C-4','FORD');
add_company_stock('C-5','JANATA Bank');
add_company_stock('C-6','Square');
add_company_stock('C-7','APEX');
add_company_stock('C-8','FACEBOOK');
add_company_stock('C-100','TO BE DELETED');

add_offer_to_sell('101','C-1',101.1,10000);
add_offer_to_sell('102','C-1',97.5,20000);
add_offer_to_sell('103','C-3',1000,5000);
add_offer_to_sell('104','C-4',975,7000);
add_offer_to_sell('102','C-2',75,15000);
add_offer_to_sell('104','C-6',401,15750);
add_offer_to_sell('101','C-7',98,100000);
add_offer_to_sell('103','C-8',947,23033);

add_owned_stock('TESLA',1000,990,'U-24','103','C-3');
add_owned_stock('APEX',5000,70,'U-98','101','C-7');
add_owned_stock('Square',1400,350,'U-21','104','C-6');
add_owned_stock('TESLA',1000,970,'U-29','103','C-3');
add_owned_stock('BRAC Bank',700,90,'U-20','102','C-2');
add_owned_stock('FACEBOOK',300,800,'U-24','103','C-8');



add_yearly_revenue(12540.5,'U-24','C-3','103'); 
add_yearly_revenue(20045,'U-98','C-7','101');
add_yearly_revenue(12761,'U-21','C-6','104');
add_yearly_revenue(14292.5,'U-29','C-3','103');
add_yearly_revenue(5000,'U-20','C-2','102');
add_yearly_revenue(10342,'U-24','C-8','103');
END;
/

--DESCRIBE COMMAND
DESCRIBE Stock_Exchange;
DESCRIBE USERS;
DESCRIBE company_stock;
DESCRIBE owned_stock;
DESCRIBE buy_sell;
DESCRIBE offer_to_sell;
DESCRIBE yearly_revenue;

--SELECT * COMMAND
select * from Stock_Exchange;
select * from USERS;
select * from company_stock;
select * from owned_stock;
select * from buy_sell;
select * from offer_to_sell;
select * from yearly_revenue;

--UPDATING A DATA/ ROW with UPDATE
select * from Stock_Exchange where exchange_id='101';
UPDATE  Stock_Exchange
SET exchange_name='Dhaka Stock Exchange' where exchange_id='101';
select * from Stock_Exchange where exchange_id='101';

--DELETED ONE ENTRY/DATA
DELETE from company_stock
where company_id='C-100';

select company_id, sum(volume)
 from offer_to_sell group by company_id having sum(volume)>1000;--GROUP BY HAVING

select company_name from company_stock where company_id in 
(select DISTINCT company_id from offer_to_sell);--USAGE OF DISTINCT AND NESTED QUERY

select (amount/12) from yearly_revenue;

select name from users where balance between 100000 and 200000;--between command
--showing who has balanace between 100000 and 200000

select user_id from buy_sell where exchange_id IN ('101', '103');
--This shows who has purchace history in stock_exchange 101 and 103

select name from users where  name LIKE 'S%';
--SHOWS THE USER WHO HAS 'S' at First OF their Name

select * from owned_stock order by quantity desc;
--Shows all users based on their quantity of stock in descending order

 select exchange_id ,sum(volume) from offer_to_sell group by exchange_id;
 --Shows the Total Volume Each Stock Exchange Currently Selling

 select company_id, avg(Price) from offer_to_sell group by company_id;
 --Show On average Stock Price of a company

 select company_id, avg(Price) from offer_to_sell group by company_id
 having avg(price)>500;
 --Shows which company has avg price more than $500



select company_name from company_stock 
where company_id in (select company_id from offer_to_sell 
	where price>500)
UNION --USAGE OF UNION
select company_name from company_stock where company_id in (select company_id from offer_to_sell
	where volume<12000);
 --Shows the stocks who has price greater than 500 or volume is less then 12000



select company_name from company_stock 
where company_id in (select company_id from offer_to_sell 
	where price>500)
INTERSECT --USAGE OF INTERSECT
select company_name from company_stock where company_id in (select company_id from offer_to_sell
	where volume<12000);
--Shows the stocks who has price greater than 500 AND volume is less then 12000



select company_name from company_stock where company_id in (select company_id from offer_to_sell
	where volume<12000)
MINUS
select company_name from company_stock 
where company_id in (select company_id from offer_to_sell 
	where price>500);
--First Query Returns ford,tesla,Exim. Second Returns Ford and Tesla. So Final Result is Exim.



select company_name from company_stock 
where company_id in (select company_id from offer_to_sell 
	where price>500)
UNION
select company_name from company_stock where company_id in 
(select company_id from offer_to_sell where volume<12000)
INTERSECT
select company_name from company_stock where company_id in
(select company_id from offer_to_sell where exchange_id='101');
--Here Union would be Executed At first as It is in the left of Intersect

 select * from users u JOIN owned_stock o
 USING (user_id);-- USING KEYWORD USED HERE
 --QUERY show full details of the users who has stocks.

select u.name from 
users u JOIN owned_stock o
on u.user_id=o.user_id;
--THE QUERY SHOWS THE USER WHO HAVE STOCKS

select name, company_name from users natural JOIN OWNED_STOCK;
--USE OF NATURAL JOIN

select exchange_name,user_id,company_name from Stock_Exchange s cross JOIN owned_stock o
where s.exchange_id=o.exchange_id;
--USED CROSS JOIN WITH where Condition.


select name,exchange_id from users u left outer JOIN buy_sell b on u.user_id=b.user_id;
--USED LEFT OUTER JOIN
--QUERY RETURNS ALL the user name and Exchange ID for the users who have made trasaction
--also returns the name of users who had not made any trasaction yet

select s.exchange_name,b.exchange_id from buy_sell b
right outer JOIN stock_exchange s on s.exchange_id=b.exchange_id;
--RIGHT OUTER JOIN
--QUERY RETURNS THE stock exchange who has already sold some stocks
--Also returns the exchnage name and ID who has not sold any stock.


select s1.exchange_name from 
stock_exchange s1 JOIN stock_exchange s2 
on s1.opening_time=s2.closing_time;
--SELF JOIN
--RETURNS THE Stock Exhanges if Some stock Exchange's 
--Closing time is another one's opening time


select name, EXTRACT(YEAR from reg_date) AS JOINING_YEAR from users;
--Shows the user Name and Joining Year Of Each User.
--Usage of AS


SET SERVEROUTPUT ON
DECLARE 
	open stock_exchange.opening_time%type;
	lim varchar(40);
BEGIN
	lim:='Dhaka Stock Exchange';
	select opening_time into open from Stock_Exchange 
	where exchange_name=lim;
	DBMS_OUTPUT.PUT_LINE('OPENING TIME OF '||lim||' is '||open);	
END;
/
--This Query Returns the opening time of DSE 
--Usages of PL SQL block


DECLARE
	CURSOR star_customer IS select name from users
	where user_id in( select user_id from owned_stock group by user_id 
	having sum(quantity)>=1000);
	s_cur star_customer%ROWTYPE;
	c number;
BEGIN
OPEN star_customer;
	c:=1;
	LOOP
		FETCH star_customer into s_cur;
		EXIT when star_customer%NOTFOUND;
		DBMS_OUTPUT.PUT_LINE ('Star Customer '||c||': '||s_cur.name);
		c:=c+1;
		END LOOP;
CLOSE star_customer;
END;
/
--If any customer has more than 1000 Stocks, he/she is a star customer
--This Query Returns the name of Star Customers
-- Usage of CURSOR



create or replace view Revenue_View AS
	select u.name,user_id, sum(amount) AS TOTAL_REVENUE from users u natural JOIN yearly_revenue y group by (user_id,name); 
--THIS view shows the total revenue of each users;


select name, (TOTAL_REVENUE*.25) AS TAX_PAYABLE from Revenue_View where TOTAL_REVENUE>5000;
--Shows the user name and Total Tax of Each user who have earned more than 5000 in previous year.


SET SERVEROUTPUT ON
BEGIN
dbms_output.put_line('Total REVENUE OF USER ABRAR IS: '|| show_revenue('U-24'));
dbms_output.put_line('Total REVENUE OF USER SADMAN IS: '|| show_revenue('U-20'));
END;
/
--Prints the total Revenue against  user ID;



BEGIN
 calculate_profit_loss(300,'U-24','C-3','103');
END;
 /
 --Returns the Profit/Loss if this stock is sold

--USE OF savepoint
SAVEPOINT s1;

insert into company_stock values ('C-1234','DEMO COMPANY' );

select * from company_stock;

ROLLBACK to s1;

select * from company_stock;

SET SERVEROUTPUT ON
DECLARE
v_num1 Number;
v_num2 Number;
v_sum  Number;

BEGIN
V_num1 := &Number1;
V_num2 := &Number2;

V_sum := v_num1 + v_num2 ;

Dbms_Output.Put_Line ('The Sum of number is :' || v_sum);

END;
/