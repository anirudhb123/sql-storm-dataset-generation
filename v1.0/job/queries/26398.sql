WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2020
    GROUP BY m.id, m.title, m.production_year, k.keyword
),

most_frequent_titles AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM ranked_movies
    WHERE rank = 1
),

actors_with_roles AS (
    SELECT 
        a.name AS actor_name,
        r.role,
        c.movie_id,
        m.title
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    JOIN title m ON c.movie_id = m.id
    WHERE m.production_year BETWEEN 2000 AND 2020
    AND (LOWER(a.name) LIKE '%john%' OR LOWER(a.name) LIKE '%doe%')
)

SELECT 
    f.title AS "Most Frequent Title",
    f.production_year,
    f.keyword AS "Main Keyword",
    COUNT(DISTINCT ar.actor_name) AS "Unique Actors",
    STRING_AGG(DISTINCT ar.actor_name, ', ') AS actor_list
FROM most_frequent_titles f
JOIN actors_with_roles ar ON f.movie_id = ar.movie_id
GROUP BY f.movie_id, f.title, f.production_year, f.keyword
ORDER BY f.production_year DESC, "Unique Actors" DESC;
