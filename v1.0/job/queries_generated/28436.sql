WITH keywords_with_movies AS (
    SELECT mk.movie_id, k.keyword, COUNT(*) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
),
top_movies AS (
    SELECT ak.title, t.production_year, COUNT(DISTINCT ak.name) AS aka_name_count
    FROM aka_title ak
    JOIN title t ON ak.movie_id = t.id
    GROUP BY ak.title, t.production_year
    ORDER BY aka_name_count DESC
    LIMIT 10
),
cast_role_counts AS (
    SELECT c.movie_id, r.role AS role, COUNT(c.id) AS role_count
    FROM cast_info c
    JOIN role_type r ON c.person_role_id = r.id
    GROUP BY c.movie_id, r.role
)
SELECT 
    t.title,
    t.production_year,
    k.keyword,
    kw.keyword_count,
    cr.role,
    cr.role_count,
    ak.aka_name_count
FROM top_movies ak
LEFT JOIN keywords_with_movies kw ON ak.title = kw.keyword
LEFT JOIN cast_role_counts cr ON ak.title = (
    SELECT title FROM aka_title WHERE movie_id = cr.movie_id LIMIT 1
)
ORDER BY ak.aka_name_count DESC, kw.keyword_count DESC, cr.role_count DESC;
