
WITH movie_years AS (
    SELECT production_year, COUNT(*) AS count_movies
    FROM aka_title
    GROUP BY production_year
),
cast_roles AS (
    SELECT ci.movie_id, rt.role, COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
top_movies AS (
    SELECT at.id AS movie_id, at.title, at.production_year, 
           ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title at
    JOIN cast_info ci ON at.id = ci.movie_id
    WHERE at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY at.id, at.title, at.production_year
)
SELECT 
    mv.title AS movie_title,
    mv.production_year,
    COALESCE(cr.role, 'Unknown') AS role_type,
    cr.role_count,
    COALESCE(mw.count_movies, 0) AS movies_in_year
FROM top_movies mv
LEFT JOIN cast_roles cr ON mv.movie_id = cr.movie_id
LEFT JOIN movie_years mw ON mv.production_year = mw.production_year
WHERE mv.rank <= 5
ORDER BY mv.production_year DESC, movies_in_year DESC;
