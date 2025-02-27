WITH RECURSIVE CompanyHierarchy AS (
    SELECT c.id AS company_id, c.name AS company_name, mc.movie_id, mc.note,
           1 AS level
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    WHERE c.country_code = 'USA'
    
    UNION ALL

    SELECT c.id, c.name, mc.movie_id, mc.note, level + 1
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN CompanyHierarchy ch ON mc.movie_id = ch.movie_id
    WHERE level < 5
), 
MovieCast AS (
    SELECT m.id AS movie_id, m.title, COUNT(DISTINCT ci.person_id) AS actor_count,
           STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE m.production_year >= 2000
    GROUP BY m.id, m.title
), 
HighBudgetMovies AS (
    SELECT movie_id, title
    FROM movie_info
    WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    AND CAST(info AS INTEGER) > 100000000
), 
MovieStatistics AS (
    SELECT mc.movie_id, mc.title, 
           ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY find_in_set(CONCAT(' ', ak.name), ',')) AS actor_rank,
           COALESCE(ch.company_name, 'Independent') AS production_company
    FROM MovieCast mc
    LEFT JOIN CompanyHierarchy ch ON mc.movie_id = ch.movie_id
)
SELECT ms.title, ms.actor_count, ms.actor_rank, ms.production_company
FROM MovieStatistics ms
JOIN HighBudgetMovies hbm ON ms.movie_id = hbm.movie_id
WHERE ms.actor_count > 1 OR ms.production_company IS NULL
ORDER BY ms.actor_rank, ms.title;
