declare

    cursor table_column is
        select distinct cons_col.table_name, tab_col.column_name
        from user_constraints cons, user_cons_columns cons_col, user_tab_columns tab_col, user_objects obj
        where cons_col.constraint_name = cons.constraint_name and cons_col.column_name = tab_col.column_name and tab_col.table_name = obj.object_name
        and obj.object_type = 'TABLE' and cons.constraint_type = 'P' and tab_col.data_type = 'NUMBER';

   max_id number;
   drop_or_not number;
   
begin

     for tab_col in table_column loop

          select  count(*)
          into drop_or_not
          from user_sequences 
          where sequence_name = tab_col.table_name||'_SEQ';
          
          if drop_or_not != 0 then
              execute immediate 'drop sequence ' || tab_col.table_name || '_SEQ';
          end if;
          
          execute immediate 'select nvl(max(' || tab_col.column_name || '), 0)
          from ' || tab_col.table_name
          into max_id;
          
          execute immediate 'CREATE SEQUENCE ' || tab_col.table_name || '_SEQ ' ||
          'START WITH ' || to_char(max_id + 1) ||
          ' INCREMENT BY 1
          MAXVALUE 999999999999999999999999999
          MINVALUE 1
          NOCYCLE
          CACHE 20
          NOORDER'; 
          
         execute immediate 'CREATE OR REPLACE TRIGGER '|| tab_col.table_name || '_TRG 
         BEFORE INSERT ON ' || tab_col.table_name ||
         ' FOR EACH ROW
         BEGIN
         :new.' || tab_col.column_name || ' := ' || tab_col.table_name || '_SEQ.nextval;
          END;';

     end loop; 
      
end;
