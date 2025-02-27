WITH RecursiveCast AS (
    SELECT c.movie_id, 
           c.person_id,
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rn,
           p.name AS person_name,
           p.gender
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
), MovieTitles AS (
    SELECT t.title, 
           t.production_year, 
           t.id AS title_id,
           k.keyword,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
), CompanyInfo AS (
    SELECT mc.movie_id, 
           cn.name AS company_name,
           ct.kind AS company_type,
           COALESCE(mc.note, 'N/A') AS note
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
), MovieInfoExtended AS (
    SELECT m.movie_id, 
           m.title, 
           m.production_year, 
           COUNT(DISTINCT ci.person_id) AS num_cast,
           STRING_AGG(DISTINCT ci.person_name, ', ') AS cast_list,
           COALESCE(SUM(mi.info::integer), 0) AS total_info_entries
    FROM MovieTitles m
    LEFT JOIN RecursiveCast ci ON m.title_id = ci.movie_id
    LEFT JOIN movie_info mi ON m.title_id = mi.movie_id
    GROUP BY m.movie_id, m.title, m.production_year
), FinalOutput AS (
    SELECT m.title, 
           m.production_year, 
           m.num_cast,
           m.cast_list,
           ci.company_name,
           ci.company_type,
           m.total_info_entries,
           CASE 
               WHEN m.num_cast > 10 THEN 'Large Cast'
               WHEN m.num_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
               ELSE 'Small Cast'
           END AS cast_size_category
    FROM MovieInfoExtended m
    LEFT JOIN CompanyInfo ci ON m.movie_id = ci.movie_id
    WHERE m.production_year >= (SELECT MAX(production_year) - 20 FROM aka_title)
    ORDER BY m.production_year DESC, m.num_cast DESC
)
SELECT *
FROM FinalOutput
WHERE company_type IS NOT NULL
  AND (CAST(total_info_entries AS INTEGER) > 5 OR company_name IS NULL)
UNION ALL
SELECT title, 
       production_year, 
       num_cast, 
       cast_list, 
       'Unknown' AS company_name,
       'Unknown' AS company_type,
       total_info_entries,
       'No Cast Info' AS cast_size_category
FROM FinalOutput
WHERE company_type IS NULL
ORDER BY production_year DESC, num_cast DESC;
