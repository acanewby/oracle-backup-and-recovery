-- ======================================
-- (c) 2018 Adrian Newby
-- ======================================
-- Generates and executes a cold backup for supplied database

-- Syntax: execute-coldbackup.sql dbName &&tgtDir
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

spool &&tgtDir./coldbackup-&&db..sql

declare
	opSys VARCHAR2(16) := '&&os.';
begin
  dbms_output.enable(NULL);
  dbms_output.put_line('set echo on');
  dbms_output.put_line('set define off');
  dbms_output.put_line('spool &&tgtDir./coldbackup-&&db..log');
  dbms_output.put_line('select to_char(sysdate, ''YYYYMMDD HH24:MI:SS'') bkp_start from dual;');

       	dbms_output.put_line('-- DATA -------------------------------------------------------');

	-- ===================================
	-- Data files
	-- ===================================
	for item in ( SELECT NAME FROM V$DATAFILE )
	loop
		-- We must handle Linux differently because gzip won't work against a raw device directly, like it does on a raw AIX logical volume
		IF opSys = 'Linux' THEN
			dbms_output.put_line('!dd if='|| item.name ||' of=' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' bs=1024k'); 
		    dbms_output.put_line('!nohup gzip -f ' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' &');
		ELSE
			dbms_output.put_line('!gzip -cf < '|| item.name ||' > ' ||' &&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || '.gz' );
		END IF;
	end loop;

       	dbms_output.put_line('-- TEMP -------------------------------------------------------');

	-- ===================================
	-- Temp files
	-- ===================================
	for item in ( SELECT NAME FROM V$TEMPFILE )
	loop
		-- We must handle Linux differently because gzip won't work against a raw device directly, like it does on a raw AIX logical volume
		IF opSys = 'Linux' THEN
			dbms_output.put_line('!dd if='|| item.name ||' of=' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' bs=1024k'); 
		    dbms_output.put_line('!nohup gzip -f ' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' &');
		ELSE
			dbms_output.put_line('!gzip -cf < '|| item.name ||' > ' ||' &&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || '.gz' );
		END IF;
	end loop;

       	dbms_output.put_line('-- REDO -------------------------------------------------------');

	-- ===================================
	-- Redo log files
	-- ===================================
	for item in ( SELECT MEMBER FROM V$LOGFILE )
	loop
		-- We must handle Linux differently because gzip won't work against a raw device directly, like it does on a raw AIX logical volume
		IF opSys = 'Linux' THEN
			dbms_output.put_line('!dd if='|| item.member ||' of=' || '&&tgtDir.' || '/' ||  replace(item.member,'/','[slash]') || ' bs=1024k'); 
		    dbms_output.put_line('!nohup gzip -f ' || '&&tgtDir.' || '/' ||  replace(item.member,'/','[slash]') || ' &');
		ELSE
			dbms_output.put_line('!gzip -cf < '|| item.member ||' > ' ||' &&tgtDir.' || '/' ||  replace(item.member,'/','[slash]') || '.gz' );
		END IF;
	end loop;

       	dbms_output.put_line('-- CTRL -------------------------------------------------------');

	-- ===================================
	-- Control files
	-- ===================================
	for item in ( SELECT NAME FROM V$CONTROLFILE )
	loop
		-- We must handle Linux differently because gzip won't work against a raw device directly, like it does on a raw AIX logical volume
		IF opSys = 'Linux' THEN
			dbms_output.put_line('!dd if='|| item.name ||' of=' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' bs=1024k'); 
		    dbms_output.put_line('!nohup gzip -f ' || '&&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || ' &');
		ELSE
			dbms_output.put_line('!gzip -cf < '|| item.name ||' > ' ||' &&tgtDir.' || '/' ||  replace(item.name,'/','[slash]') || '.gz' );
		END IF;
	end loop;

       	dbms_output.put_line('---------------------------------------------------------------');

  dbms_output.put_line('select to_char(sysdate, ''YYYYMMDD HH24:MI:SS'') bkp_end from dual;');

  dbms_output.put_line('spool off');
  
end;
/
spool off
set heading on
set feedback on
set serveroutput off

-- run the script
shutdown immediate
@/&&tgtDir./coldbackup-&&db..sql
startup

exit

