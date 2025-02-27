WITH actor_movie_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name, t.title, t.production_year, ct.kind
),
actor_summary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(*) AS movie_count,
        MIN(movie_year) AS first_movie_year,
        MAX(movie_year) AS last_movie_year,
        STRING_AGG(DISTINCT movie_title, '; ') AS movies
    FROM 
        actor_movie_details
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.movie_count,
    a.first_movie_year,
    a.last_movie_year,
    a.movies,
    AVG(LENGTH(m.movie_title)) AS avg_title_length
FROM 
    actor_summary a
JOIN 
    actor_movie_details m ON a.actor_id = m.actor_id
GROUP BY 
    a.actor_id, a.actor_name, a.movie_count, a.first_movie_year, a.last_movie_year
ORDER BY 
    a.movie_count DESC, a.first_movie_year ASC
LIMIT 10;
