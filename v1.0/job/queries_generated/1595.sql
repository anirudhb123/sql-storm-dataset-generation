WITH movie_years AS (
    SELECT production_year, COUNT(*) AS movie_count
    FROM aka_title
    WHERE production_year IS NOT NULL
    GROUP BY production_year
),
top_companies AS (
    SELECT mc.company_id, c.name AS company_name, COUNT(*) AS movie_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.company_id, c.name
    ORDER BY movie_count DESC
    LIMIT 10
),
director_credits AS (
    SELECT ci.movie_id, ci.person_id, r.role AS director_role
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    WHERE r.role ILIKE '%director%'
),
titles_with_directors AS (
    SELECT t.title, t.production_year, tc.company_name, dc.person_id
    FROM aka_title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN top_companies tc ON mc.company_id = tc.company_id
    LEFT JOIN director_credits dc ON t.id = dc.movie_id
    WHERE t.production_year IS NOT NULL
),
title_stats AS (
    SELECT title, production_year, company_name,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS title_rank,
           COUNT(*) OVER (PARTITION BY production_year) AS total_titles
    FROM titles_with_directors
)
SELECT production_year, 
       STRING_AGG(title || ' (Directed by: ' || COALESCE(cast_info.name, 'Unknown') || ')', ', ') AS titles,
       COUNT(DISTINCT(company_name)) AS distinct_companies,
       AVG(title_rank) AS average_title_rank
FROM title_stats ts
LEFT JOIN aka_name cast_info ON ts.person_id = cast_info.person_id
GROUP BY production_year
HAVING COUNT(DISTINCT(title)) > 5
ORDER BY production_year DESC;
