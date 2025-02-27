WITH movie_actors AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        c.movie_id AS movie_id, 
        t.title AS movie_title, 
        t.production_year AS release_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.name LIKE '%Smith%'  
    GROUP BY 
        a.id, a.name, c.movie_id, t.title, t.production_year
),
actor_summary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS total_movies,
        MIN(release_year) AS first_movie_year,
        MAX(release_year) AS last_movie_year
    FROM 
        movie_actors
    GROUP BY 
        actor_id, actor_name
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title, 
        cc.kind AS company_type,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type cc ON mc.company_type_id = cc.id
    GROUP BY 
        m.id, m.title, cc.kind
)
SELECT 
    asu.actor_name,
    asu.total_movies,
    asu.first_movie_year,
    asu.last_movie_year,
    md.movie_title,
    md.company_type,
    md.companies,
    ma.keywords
FROM 
    actor_summary asu
JOIN 
    movie_actors ma ON asu.actor_id = ma.actor_id
JOIN 
    movie_details md ON ma.movie_id = md.movie_id
ORDER BY 
    asu.total_movies DESC, 
    asu.last_movie_year DESC
LIMIT 10;