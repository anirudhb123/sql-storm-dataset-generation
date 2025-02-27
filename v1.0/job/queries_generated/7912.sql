WITH actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    GROUP BY 
        c.person_id
),
top_actors AS (
    SELECT 
        ak.name AS actor_name, 
        amc.movie_count
    FROM 
        aka_name ak
    JOIN 
        actor_movie_counts amc ON ak.person_id = amc.person_id
    ORDER BY 
        amc.movie_count DESC
    LIMIT 10
),
movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        ak.person_id IN (SELECT person_id FROM top_actors)
    GROUP BY 
        t.title, t.production_year, ak.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.keyword_count
FROM 
    movie_details md
JOIN 
    aka_title at ON md.movie_title = at.title
WHERE 
    at.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
