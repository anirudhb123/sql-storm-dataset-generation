WITH ranked_actors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
),
top_actors AS (
    SELECT 
        actor_id, 
        actor_name 
    FROM 
        ranked_actors 
    ORDER BY 
        movie_count DESC 
    LIMIT 10
),
movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        co.name AS company_name,
        k.keyword AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    ta.actor_name,
    md.movie_title,
    md.production_year,
    md.company_name,
    STRING_AGG(md.keywords, ', ') AS keywords_list
FROM 
    top_actors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    movie_details md ON ci.movie_id = md.movie_id
GROUP BY 
    ta.actor_name, md.movie_title, md.production_year, md.company_name
ORDER BY 
    ta.actor_name, md.production_year DESC;
