
WITH title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
detailed_info AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ti.keywords,
        ai.actor_count,
        ai.actors,
        ti.companies
    FROM 
        title_info ti
    LEFT JOIN 
        actor_info ai ON ti.title_id = ai.movie_id
)
SELECT 
    di.title,
    di.production_year,
    di.keywords,
    di.actor_count,
    di.actors,
    di.companies
FROM 
    detailed_info di
WHERE 
    di.actor_count > 5
ORDER BY 
    di.production_year DESC, 
    di.title;
