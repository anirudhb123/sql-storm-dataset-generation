WITH actor_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS year,
        k.keyword AS movie_keyword
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.name IS NOT NULL
    AND t.title IS NOT NULL
),

movie_info_details AS (
    SELECT 
        t.title AS movie_title,
        m.info AS movie_info,
        mt.kind AS info_type
    FROM title t
    JOIN movie_info m ON t.id = m.movie_id
    JOIN info_type mt ON m.info_type_id = mt.id
    WHERE mt.info LIKE '%Award%'
),

combined_info AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.year,
        am.movie_keyword,
        mid.movie_info
    FROM actor_movies am
    JOIN movie_info_details mid ON am.movie_title = mid.movie_title
)

SELECT 
    actor_name,
    movie_title,
    year,
    ARRAY_AGG(DISTINCT movie_keyword) AS keywords,
    STRING_AGG(DISTINCT movie_info, '; ') AS awards_info
FROM combined_info
GROUP BY actor_name, movie_title, year
ORDER BY actor_name, year DESC;
