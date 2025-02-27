WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.actor_count,
    ms.actor_names,
    ms.keywords,
    cs.company_names,
    cs.company_types,
    ms.first_year,
    ms.last_year
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyStats cs ON ms.movie_id = cs.movie_id
ORDER BY 
    ms.first_year DESC, 
    ms.actor_count DESC;
