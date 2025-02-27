WITH actor_movie_counts AS (
    SELECT 
        a.personal_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
),
top_actors AS (
    SELECT 
        p.id AS actor_id,
        p.name AS actor_name,
        ac.movie_count
    FROM 
        aka_name p
    JOIN 
        actor_movie_counts ac ON p.person_id = ac.personal_id
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
),
movie_details AS (
    SELECT
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    md.title,
    md.production_year,
    md.keywords,
    md.company_names
FROM 
    top_actors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    movie_details md ON ci.movie_id = md.id
ORDER BY 
    ta.movie_count DESC, md.production_year DESC;
