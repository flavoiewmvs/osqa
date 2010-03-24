  CREATE OR REPLACE FUNCTION public.create_plpgsql_language ()
      RETURNS TEXT
      AS $$
          CREATE LANGUAGE plpgsql;
          SELECT 'language plpgsql created'::TEXT;
      $$
  LANGUAGE 'sql';

  SELECT CASE WHEN
        (SELECT true::BOOLEAN
           FROM pg_language
          WHERE lanname='plpgsql')
      THEN
        (SELECT 'language already installed'::TEXT)
      ELSE
        (SELECT public.create_plpgsql_language())
      END;

  DROP FUNCTION public.create_plpgsql_language ();

  CREATE OR REPLACE FUNCTION set_question_tsv() RETURNS TRIGGER AS $$
  begin
    new.tsv :=
       setweight(to_tsvector('english', coalesce(new.tagnames,'')), 'A') ||
       setweight(to_tsvector('english', coalesce(new.title,'')), 'B') ||
       setweight(to_tsvector('english', coalesce(new.html,'')), 'C');
    RETURN new;
  end
  $$ LANGUAGE plpgsql;

     CREATE OR REPLACE FUNCTION public.create_tsv_question_column ()
      RETURNS TEXT
      AS $$
          ALTER TABLE question ADD COLUMN tsv tsvector;
          	  CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
	  ON question FOR EACH ROW EXECUTE PROCEDURE set_question_tsv();

	    CREATE INDEX question_tsv ON question USING gin(tsv);

          SELECT 'tsv column created'::TEXT;
      $$
  LANGUAGE 'sql';

  SELECT CASE WHEN
     (SELECT true::BOOLEAN FROM pg_attribute WHERE attrelid = (SELECT oid FROM pg_class WHERE relname = 'question') AND attname = 'tsv')
  THEN
     (SELECT 'Tsv column already exists'::TEXT)
  ELSE
     (SELECT public.create_tsv_question_column())

  END;
