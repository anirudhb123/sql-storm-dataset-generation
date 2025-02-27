WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword LIKE '%action%'
),
actor_counts AS (
    SELECT 
        actor_name,
        COUNT(movie_id) AS total_movies
    FROM 
        movie_details
    GROUP BY 
        actor_name
),
top_actors AS (
    SELECT 
        actor_name,
        total_movies,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM 
        actor_counts
)
SELECT 
    actor_name,
    total_movies
FROM 
    top_actors
WHERE 
    rank <= 10;
