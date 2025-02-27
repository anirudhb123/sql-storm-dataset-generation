
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
actor_counts AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actors) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_title
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.keywords,
    ac.actor_count
FROM 
    movie_details md
JOIN 
    actor_counts ac ON md.movie_title = ac.movie_title
ORDER BY 
    md.production_year DESC, ac.actor_count DESC
FETCH FIRST 100 ROWS ONLY;
