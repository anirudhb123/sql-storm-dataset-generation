WITH movie_details AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year, k.keyword
),
actor_info AS (
    SELECT 
        p.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    GROUP BY 
        p.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
top_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keyword,
        md.actor_count,
        ROW_NUMBER() OVER (PARTITION BY md.keyword ORDER BY md.actor_count DESC) as rank
    FROM 
        movie_details md
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keyword,
    tm.actor_count,
    ai.actor_name,
    ai.movie_count
FROM 
    top_movies tm
JOIN 
    actor_info ai ON tm.actor_count = ai.movie_count
WHERE 
    tm.rank <= 3
ORDER BY 
    tm.keyword, tm.actor_count DESC;
