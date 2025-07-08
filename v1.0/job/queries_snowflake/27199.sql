WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS company_names,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_count AS (
    SELECT 
        movie_id,
        COUNT(actor_names) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_id
),
company_count AS (
    SELECT 
        movie_id,
        COUNT(company_names) AS company_count
    FROM 
        movie_details
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ARRAY_TO_STRING(md.keywords, ', ') AS keywords,
    ac.actor_count,
    cc.company_count
FROM 
    movie_details md
JOIN 
    actor_count ac ON md.movie_id = ac.movie_id
JOIN 
    company_count cc ON md.movie_id = cc.movie_id
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC;
