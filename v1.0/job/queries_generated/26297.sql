WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT a.id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000  -- Restrict to modern movies
    GROUP BY 
        t.id, t.title, t.production_year, c.name
), actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
)

SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.keywords,
    md.actor_count,
    ad.actor_name,
    ad.movies_count
FROM 
    movie_details md
JOIN 
    actor_details ad ON md.actor_count > 5  -- Filter to movies featuring "prolific" actors
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
