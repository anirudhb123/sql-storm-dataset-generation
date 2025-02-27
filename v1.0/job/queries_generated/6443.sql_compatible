
WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.actor_names,
    ms.keyword_count,
    cs.company_count,
    cs.company_names
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyStats cs ON ms.movie_id = cs.movie_id
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, ms.cast_count DESC, cs.company_count DESC;
