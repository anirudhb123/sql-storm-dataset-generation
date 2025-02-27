
WITH movie_summary AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    INNER JOIN 
        complete_cast cc ON t.id = cc.movie_id
    INNER JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2022
    GROUP BY 
        t.id, t.title, t.production_year
),
company_summary AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.actors,
    cs.companies,
    cs.company_types,
    TRIM(BOTH ',' FROM STRING_AGG(DISTINCT a.name, ',')) AS all_actors
FROM 
    movie_summary ms
LEFT JOIN 
    company_summary cs ON ms.movie_id = cs.movie_id
LEFT JOIN 
    cast_info ci ON ms.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    ms.movie_id, ms.title, ms.production_year, ms.actor_count, ms.actors, cs.companies, cs.company_types
ORDER BY 
    ms.production_year DESC, ms.actor_count DESC;
