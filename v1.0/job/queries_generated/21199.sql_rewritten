WITH recursive movie_seasons AS (
    SELECT t.id AS title_id, 
           t.title, 
           t.production_year, 
           t.season_nr, 
           t.episode_nr,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.season_nr, t.episode_nr) AS episode_order
    FROM title t
    WHERE t.season_nr IS NOT NULL
), 
cast_summary AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS total_cast,
           STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
company_info AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, '; ') AS companies,
           STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)

SELECT t.id AS title_id,
       t.title,
       ms.season_nr,
       ms.episode_nr,
       cs.total_cast,
       cs.cast_names,
       c.companies,
       c.company_types,
       
       CASE 
           WHEN cs.total_cast IS NULL THEN 'No Cast Information'
           ELSE 'Cast Available'
       END AS cast_info_status,
       
       (SELECT COUNT(DISTINCT mk.keyword_id) 
        FROM movie_keyword mk 
        WHERE mk.movie_id = t.id) AS total_keywords,
       
       
       COALESCE(NULLIF(c.companies, ''), '<No Production Companies Listed>') AS production_info

FROM title t
LEFT JOIN movie_seasons ms ON t.id = ms.title_id
LEFT JOIN cast_summary cs ON t.id = cs.movie_id
LEFT JOIN company_info c ON t.id = c.movie_id
WHERE t.production_year IS NOT NULL
  AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
       OR t.production_year > 2000)
ORDER BY t.production_year DESC, ms.season_nr ASC NULLS LAST
LIMIT 100;