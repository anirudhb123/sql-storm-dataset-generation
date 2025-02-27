WITH movie_summary AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS production_company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT a2.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name a2 ON ci.person_id = a2.person_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        a.production_year >= 1990
    GROUP BY 
        a.id, a.title, a.production_year
),
actor_summary AS (
    SELECT 
        a2.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT a.title, ', ') AS movies
    FROM 
        aka_name a2
    JOIN 
        cast_info ci ON a2.person_id = ci.person_id
    JOIN 
        aka_title a ON ci.movie_id = a.id
    GROUP BY 
        a2.name
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.production_company_count,
    ms.keyword_count,
    ms.actors,
    ms.company_types,
    asu.actor_name,
    asu.movie_count,
    asu.movies
FROM 
    movie_summary ms
LEFT JOIN 
    actor_summary asu ON ms.actors LIKE '%' || asu.actor_name || '%'
ORDER BY 
    ms.production_year DESC, ms.movie_title;
