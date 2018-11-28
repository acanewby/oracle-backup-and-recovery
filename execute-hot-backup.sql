-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================
-- Generates and executes a hot backup for supplied database
-- Syntax: execute-hotbackup.sql dbName &&tgtDir
-- ======================================



DEFINE db=&1.
DEFINE tgtDir=&2.
DEFINE os=&3.

set serveroutput on
set heading off
set feedback off
set linesize 255 
set verify off

host mkdir -p &&tgtDir.

spool /&&tgtDir./hotbackup-&&db..sql

declare
	tbsName VARCHAR2(30);
	opSys VARCHAR2(16) := '&&os.';
begin
  dbms_output.enable(NULL);
  dbms_output.put_line('set echo on');
  dbms_output.put_line('set define off');
  dbms_output.put_line('spool &&tgtDir./hotbackup-&&db..log');
  dbms_output.put_line('select to_char(sysdate, ''YYYYMMDD HH24:MI:SS'') bkp_start from dual;');

	for item in (select tablespace_name
        	from dba_tablespaces
        	where status <> 'READ ONLY'
			and contents <> 'TEMPORARY'
       		order by tablespace_name)
	loop

       		dbms_output.put_line('---------' || item.tablespace_name || '---------------------------');
  		dbms_output.put_line('alter tablespace '|| item.tablespace_name ||' begin backup;');

		select item.tablespace_name
			into tbsName
			from dual;

		for item in (select file_name
        		from dba_data_files
        		where tablespace_name = tbsName
       			order by file_name )
		loop
		
			-- We must handle Linux differently because gzip won't work against a raw device directly, like it does on a raw AIX logical volume
			IF opSys = 'Linux' THEN
				dbms_output.put_line('!dd if='|| item.file_name ||' of=' || '&&tgtDir.' || '/' ||  replace(item.file_name,'/','[slash]') || ' bs=1024k'); 
			    dbms_output.put_line('!nohup gzip -f ' || '&&tgtDir.' || '/' ||  replace(item.file_name,'/','[slash]') || ' &');
			ELSE
				dbms_output.put_line('!gzip -cf < '|| item.file_name ||' > ' ||' &&tgtDir.' || '/' ||  replace(item.file_name,'/','[slash]') || '.gz' );
			END IF;
			
		end loop;

        	dbms_output.put_line('alter tablespace '|| item.tablespace_name ||' end backup;');
 
  	end loop;

       		dbms_output.put_line('---------------------------------------------------------');

  dbms_output.put_line('alter database backup controlfile to trace as '||''''||'&&tgtDir.'||'/backup-controlfile.'||to_char(sysdate,'DDMMYYYYHH24MISS')||''''||';');


  dbms_output.put_line('alter database backup controlfile to '||''''||'&&tgtDir.'||'/control.'||to_char(sysdate,'DDMMYYYYHH24MISS')||''''||';');

  dbms_output.put_line('alter system switch logfile;');

  dbms_output.put_line('select to_char(sysdate, ''YYYYMMDD HH24:MI:SS'') bkp_end from dual;');
  dbms_output.put_line('spool off');
  
  dbms_output.put_line('exit;');
end;
/
spool off
set heading on
set feedback on
set serveroutput off

-- run the script
@/&&tgtDir./hotbackup-&&db..sql

exit

