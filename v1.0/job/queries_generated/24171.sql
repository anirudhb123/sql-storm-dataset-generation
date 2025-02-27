WITH RecursiveTitle AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id, t.imdb_index,
           ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CTE_Cast AS (
    SELECT c.movie_id, STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
           COUNT(DISTINCT c.person_id) AS cast_count, 
           SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL
    GROUP BY c.movie_id
),
Movie_Info AS (
    SELECT m.movie_id, mi.info AS info_text,
           CASE WHEN m.production_year < 2000 THEN 'Classic' ELSE 'Modern' END AS era_label
    FROM movie_info m
    JOIN movie_info_idx mi ON m.movie_id = mi.movie_id
    WHERE mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
),
CEO_Movie_Companies AS (
    SELECT mc.movie_id, 
           COUNT(DISTINCT c.id) AS company_count,
           STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies mc
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE ct.kind LIKE '%CEO%'
    GROUP BY mc.movie_id
)
SELECT rt.title, rt.production_year, rt.kind_id,
       COALESCE(cc.cast_names, 'No cast available') AS cast_info,
       COALESCE(cc.cast_count, 0) AS total_cast,
       COALESCE(cc.notes_present, 0) AS notes_present_count,
       mi.info_text, mi.era_label,
       cm.company_count AS companies_count,
       cm.companies AS production_companies
FROM RecursiveTitle rt
LEFT JOIN CTE_Cast cc ON rt.title_id = cc.movie_id
LEFT JOIN Movie_Info mi ON rt.title_id = mi.movie_id
LEFT JOIN CEO_Movie_Companies cm ON rt.title_id = cm.movie_id
WHERE rt.rn = 1 -- Consider only the latest title per kind
  AND (mi.info_text IS NOT NULL OR cm.companies IS NOT NULL)
ORDER BY rt.production_year DESC, rt.title;

