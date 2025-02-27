
WITH RECURSIVE title_season AS (
    SELECT t.id, t.title, t.season_nr, t.episode_nr, 
           COALESCE(episode_of_id, 0) AS is_episode,
           ROW_NUMBER() OVER (PARTITION BY t.episode_of_id ORDER BY t.season_nr, t.episode_nr) AS ep_order
    FROM aka_title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'tvseries')
),
cast_with_role AS (
    SELECT c.id AS cast_id, c.person_id, c.movie_id, r.role, 
           ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order ASC) AS cast_order
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
),
person_details AS (
    SELECT p.person_id, p.info, p.note,
           COALESCE(n.name, 'Unknown') AS person_name,
           n.gender
    FROM person_info p
    LEFT JOIN name n ON p.person_id = n.imdb_id
),
movie_company_info AS (
    SELECT mc.movie_id, 
           STRING_AGG(DISTINCT co.name, ', ') AS companies_used,
           COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
movies_with_info AS (
    SELECT m.movie_id, 
           STRING_AGG(DISTINCT mi.info, '; ') AS movie_facts,
           MAX(m.production_year) AS latest_year
    FROM movie_info mi
    JOIN aka_title m ON mi.movie_id = m.movie_id
    GROUP BY m.movie_id
)
SELECT t.title,
       COALESCE(mci.companies_used, 'No Companies') AS movie_companies,
       COALESCE(mwi.movie_facts, 'No Info') AS additional_info,
       MAX(t.production_year) AS release_year,
       SUM(CASE WHEN pd.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
       SUM(CASE WHEN pd.gender = 'M' THEN 1 ELSE 0 END) AS male_count
FROM title t
LEFT JOIN title_season ts ON t.id = ts.id
LEFT JOIN cast_with_role cwr ON t.id = cwr.movie_id
LEFT JOIN person_details pd ON cwr.person_id = pd.person_id
LEFT JOIN movie_company_info mci ON t.id = mci.movie_id
LEFT JOIN movies_with_info mwi ON t.id = mwi.movie_id
GROUP BY t.title, mci.companies_used, mwi.movie_facts
ORDER BY release_year DESC, t.title
LIMIT 50 OFFSET 0;
