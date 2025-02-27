WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast <= 3
), 
actor_role_summary AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS roles_with_no_notes
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
    GROUP BY 
        ak.name
)
SELECT 
    tm.title,
    tm.production_year,
    ars.actor_name,
    ars.movie_count,
    ars.movies,
    ars.roles_with_no_notes
FROM 
    top_movies tm
LEFT JOIN 
    actor_role_summary ars ON ars.movie_count > 5
WHERE 
    tm.production_year = (SELECT MAX(production_year) FROM top_movies)
UNION ALL
SELECT 
    'N/A' AS title,
    NULL AS production_year,
    ak.name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    NULL AS movies,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS roles_with_no_notes
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
WHERE 
    ak.id NOT IN (SELECT DISTINCT person_id FROM cast_info)
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) < 1
ORDER BY 
    production_year DESC NULLS LAST, 
    movie_count DESC;
