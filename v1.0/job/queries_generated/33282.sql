WITH RECURSIVE movie_hierarchy AS (
    -- Get the root movies (those without a parent episode)
    SELECT m.id AS movie_id, m.title, m.production_year, m.kind_id,
           1 AS level
    FROM aka_title m
    WHERE m.episode_of_id IS NULL

    UNION ALL

    -- Recursively find episodes of the movies
    SELECT e.id AS movie_id, e.title, e.production_year, e.kind_id,
           mh.level + 1
    FROM aka_title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
-- Get all companies and their movie associations
company_movies AS (
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
-- Aggregate movie info including keywords
movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
-- Combine movie hierarchy, companies, and keywords
movies_info AS (
    SELECT mh.movie_id, mh.title, mh.production_year, mh.level,
           COALESCE(cm.company_name, 'Independent') AS company_name,
           COALESCE(mk.keywords, 'None') AS keywords
    FROM movie_hierarchy mh
    LEFT JOIN company_movies cm ON mh.movie_id = cm.movie_id
    LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
)
-- Final query: selecting relevant movie details
SELECT m.title, m.production_year, m.company_name, m.keywords, 
       ROW_NUMBER() OVER (PARTITION BY m.company_name ORDER BY m.production_year DESC) AS rank
FROM movies_info m
WHERE m.level = 1 -- Ensure we are only looking at root movies
AND m.production_year >= 2000
AND m.keywords LIKE '%action%'
ORDER BY m.production_year DESC, m.title;
