create table authors (
author_id number primary key,
first_name varchar2(50) not null,
last_name varchar2(50) not null,
biography varchar2(4000)
)


create table genres (
 genre_id number primary key,
 genre_name varchar2(50) not null UNIQUE
)


create table books (
book_id number primary key,
title varchar2(50) not null,
isbn varchar2(100) not null unique,
publication_year number(4),
genre_id number, 
foreign key(genre_id)  references genres(genre_id) ,
total_quantity number not null,
available_quantity number not null

)

create table Book_Authors (
book_id number primary key ,
author_id number,
FOREIGN key (book_id) REFERENCES books(book_id),
FOREIGN key (author_id) REFERENCES authors(author_id)
)


create table members(
member_id number primary key,
first_name varchar2(50) not null,
last_name varchar2(50) not null,
address varchar2(250) not null,
phone_number number(15) ,
email varchar2(50) UNIQUE not null,
membership_date date not null,
status varchar2(25) not null
) 


create table loans (
loan_id number PRIMARY key,
book_id number not null, FOREIGN key (book_id) REFERENCES books(book_id),
member_id number not null, FOREIGN key (member_id) REFERENCES members(member_id),
loan_date date not null,
due_date date not null,
return_date date,
status varchar2(25) not null
)

create table fines (
fine_id number primary key,
loan_id number , FOREIGN key (loan_id) references loans(loan_id),
member_id number , FOREIGN key (member_id) REFERENCES members(member_id),
fine_amount number(18,2) not null,
paid_date date,
status VARCHAR2(25) not null
)


create SEQUENCE author_id_seq start with 10001 increment by 1;
create SEQUENCE genre_id_seq start with 20001 increment by 1;
create SEQUENCE book_id_seq start with 30001 increment by 1;
create SEQUENCE member_id_seq start with 40001 increment by 1;
create SEQUENCE fine_id_seq start with 50001 increment by 1;
create SEQUENCE loan_id_seq start with 60001 increment by 1;
create SEQUENCE isbn_seq start with 7000000001 increment by 1;



create or replace procedure add_book  (
    p_title in books.title%type,
     p_isbn in books.isbn%type,
   p_publication_year in books.publication_year%type,
    p_genre_id in books.genre_id%type,
    p_total_quantity in books.total_quantity%type,
    p_available_quantity in books.available_quantity%type,
    p_author_fname in varchar2,
    p_author_lname in varchar2
) as 
v_isbn number(20);
v_author_id number(10);
v_book_id number(10);
begin
    
    select isbn into v_isbn from books where isbn=p_isbn;
    RAISE_APPLICATION_ERROR(-20001, 'Book with this ISBN already exists');
    
    
    exception
    when no_data_found then
    select book_id_seq.nextval into v_book_id from dual;
    insert into books (book_id,title,isbn,publication_year,genre_id,total_quantity,available_quantity) values (v_book_id,p_title,p_isbn,p_publication_year,p_genre_id,p_total_quantity,p_available_quantity);
	
    add_author (p_author_fname,p_author_lname,v_author_id);
    
    commit;
    insert into book_authors values (v_book_id,v_author_id);
    commit;
end;
/

create or replace procedure add_author (
    p_author_fname in varchar2,
    p_author_lname in varchar2,
    p_author_id out number
) as 
begin
    select author_id into p_author_id from authors where first_name = p_author_fname and last_name = p_author_lname;
   
    exception 
    when no_data_found then
    select author_id_seq.nextval into p_author_id from dual;
        insert into authors (author_id,first_name,last_name) values (p_author_id,p_author_fname,p_author_lname);
    
    commit;
    dbms_output.put_line('new author added for the new book');
end;
/

CREATE OR REPLACE PROCEDURE update_book (
    p_isbn               IN books.isbn%TYPE,
    p_title              IN books.title%TYPE DEFAULT NULL,
    p_publication_year   IN books.publication_year%TYPE DEFAULT NULL,
    p_genre_id           IN books.genre_id%TYPE DEFAULT NULL,
    p_total_quantity     IN books.total_quantity%TYPE DEFAULT NULL,
    p_available_quantity IN books.available_quantity%TYPE DEFAULT NULL,
    p_author_fname       IN VARCHAR2 DEFAULT NULL,
    p_author_lname       IN VARCHAR2 DEFAULT NULL
) AS
    v_author_id NUMBER(10);
    v_book_id   NUMBER(10);
BEGIN
    BEGIN
        SELECT
            book_id
        INTO v_book_id
        FROM
            books
        WHERE
            isbn = p_isbn;

    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'Book with this ISBN does not exists');
    END;

    IF p_title IS NOT NULL THEN
        UPDATE books
        SET
            title = p_title
        WHERE
            book_id = v_book_id;

    END IF;

    IF p_publication_year IS NOT NULL THEN
        UPDATE books
        SET
            publication_year = p_publication_year
        WHERE
            book_id = v_book_id;

    END IF;

    IF p_genre_id IS NOT NULL THEN
        UPDATE books
        SET
            genre_id = p_genre_id
        WHERE
            book_id = v_book_id;

    END IF;

    IF p_total_quantity IS NOT NULL THEN
        UPDATE books
        SET
            total_quantity = p_total_quantity
        WHERE
            book_id = v_book_id;

    END IF;

    IF p_available_quantity IS NOT NULL THEN
        UPDATE books
        SET
            available_quantity = p_available_quantity
        WHERE
            book_id = v_book_id;

    END IF;

    IF (
        p_author_fname IS NOT NULL
        AND p_author_lname IS NOT NULL
    ) THEN
        add_author(p_author_fname, p_author_lname, v_author_id);
        IF v_author_id IS NOT NULL THEN 
        --insert into book_authors values (v_book_id,v_author_id);
            UPDATE book_authors
            SET
                author_id = v_author_id
            WHERE
                book_id = v_book_id;

        END IF;

    END IF;

    COMMIT;
END;
/



create or replace procedure display_books(
    p_title in varchar2 default null,
    p_author_name in varchar2 default null,
    p_isbn in varchar2 default null,
    P_RESULTS out SYS_REFCURSOR
)as 
query_str varchar2(1000);
v_bind_count number := 0;
begin 
query_str := 'SELECT DISTINCT b.*
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE 1 = 1
';

if p_title is not null then 
query_str := query_str || 'and lower(b.title) like :p_title';
end if;

IF p_isbn IS NOT NULL THEN
        query_str := query_str || ' AND b.isbn = :isbn';
    END IF;

if p_author_name is not null then 

query_str := query_str || 'and lower(a.first_name || '' '' || a.last_name) like :p_author_name';
end if;

IF p_title IS NOT NULL AND p_isbn IS NOT NULL AND p_author_name IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING '%' || LOWER(p_title) || '%', p_isbn, '%' || LOWER(p_author_name) || '%';

ELSIF p_title IS NOT NULL AND p_isbn IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING '%' || LOWER(p_title) || '%', p_isbn;

ELSIF p_title IS NOT NULL AND p_author_name IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING '%' || LOWER(p_title) || '%', '%' || LOWER(p_author_name) || '%';

ELSIF p_isbn IS NOT NULL AND p_author_name IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING p_isbn, '%' || LOWER(p_author_name) || '%';

ELSIF p_title IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING '%' || LOWER(p_title) || '%';

ELSIF p_isbn IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING p_isbn;

ELSIF p_author_name IS NOT NULL THEN
    OPEN p_results FOR query_str
    USING '%' || LOWER(p_author_name) || '%';

ELSE
    -- If no filters provided, return all books
    query_str := 'SELECT * FROM books';
    OPEN p_results FOR query_str;
END IF;



end;
/


 create or replace procedure search_books(
    p_title in varchar2 default null,
    p_author_name in varchar2 default null,
    p_isbn in varchar2 default null
 )as

v_cursor SYS_REFCURSOR;
v_book books%rowtype;

begin
display_books(p_title,p_author_name,p_isbn,v_cursor);

loop 
fetch v_cursor into v_book;
exit when v_cursor%notfound;
dbms_output.put_line('Title: '||v_book.title || ',ISBN: '|| v_book.isbn);
end loop;
close v_cursor;
end;
/



CREATE OR REPLACE PROCEDURE member_register (
    p_first_name      VARCHAR2,
    p_last_name       VARCHAR2,
    p_address         VARCHAR2,
    p_phone_number    NUMBER,
    p_email           VARCHAR2,
    p_status          VARCHAR2
) AS
    v_member_id NUMBER(10);
BEGIN
    SELECT
        member_id
    INTO v_member_id
    FROM
        members
    WHERE
        email = lower(p_email);

    raise_application_error(-20001, 'Member already exists with the same email');
EXCEPTION
    WHEN no_data_found THEN
        INSERT INTO members (
            member_id,
            first_name,
            last_name,
            address,
            phone_number,
            email,
            membership_date,
            status
        ) VALUES (
            member_id_seq.NEXTVAL,
            p_first_name,
            p_last_name,
            p_address,
            p_phone_number,
            lower(p_email),
            sysdate,
            p_status
        );
        
        commit;
        dbms_output.put_line('New member is added Sucessfully !');

END;
/


create or replace procedure update_member (
    p_member_id       number,
    p_first_name      VARCHAR2 default null,
    p_last_name       VARCHAR2  default null,
    p_address         VARCHAR2 default null,
    p_phone_number    NUMBER default null,
    p_email           VARCHAR2 default null,
    p_status          VARCHAR2 default null
)as 
v_member_id number(10);
begin

begin
select member_id into v_member_id from members where member_id = p_member_id;
exception
when no_data_found then
RAISE_APPLICATION_ERROR(-20001, 'Please provide correct member ID, There is no member present with the given ID !');
end;

if p_first_name is not null then
update members set first_name = p_first_name where member_id = p_member_id;
end if;
if p_last_name is not null then
update members set last_name = p_last_name where member_id = p_member_id;
end if;
if p_address is not null then
update members set address = p_address where member_id = p_member_id;
end if;
if p_phone_number is not null then
update members set phone_number = p_phone_number where member_id = p_member_id;
end if;
if p_email is not null then
update members set email = p_email where member_id = p_member_id;
end if;
if p_status is not null then
update members set status = p_status where member_id = p_member_id;
end if;

commit;

dbms_output.put_line('Member with ID '||v_member_id||' is updated Sucessfully !');

end;
/


create or replace function get_member_status (
p_member_id number
)return varchar2 as
v_status varchar2(50);
begin
select status into v_status from members where member_id = p_member_id;

return v_status;
exception
when no_data_found then 
return 'NO USER FOUND !';
dbms_output.put_line('No member found with the ID !! ');
end;
/


create or replace procedure check_out_book (
p_book_id number,
p_member_id number
) as
v_member_status varchar2(50);
v_book_avail number(10);
v_member_name varchar2(50);
begin 

select first_name into v_member_name from members where member_id=p_member_id;
v_member_status := member_management_pkg.get_member_status(p_member_id);
begin
v_book_avail := book_management_pkg.check_availability(p_book_id);
exception
when no_data_found then
raise_application_error(-20002,'Book is not availble, Please check !');
end;

if v_member_status = 'Active' then
dbms_output.put_line ('user is active');
if v_book_avail > 0 then
dbms_output.put_line ('book is avaialable');
insert into loans (loan_id,book_id,member_id,loan_date,due_date,return_date,status) values (loan_id_seq.nextval,p_book_id,p_member_id,sysdate,sysdate+30,null,'open');
update books set available_quantity = v_book_avail - 1 where book_id = p_book_id;
dbms_output.put_line ('book is issued to the user '|| v_member_name);
commit;
end if;

else
raise_application_error(-20001,'user is inactive, Please check !');
end if;


end;
/
