WITH MovieStats AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 1980 AND 2020
    GROUP BY 
        t.title, t.production_year
),
CompanyStats AS (
    SELECT
        t.title AS movie_title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.title
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.actor_count,
    ms.cast_names,
    ms.keywords,
    cs.companies,
    cs.company_types
FROM 
    MovieStats ms
LEFT JOIN 
    CompanyStats cs ON ms.movie_title = cs.movie_title
ORDER BY 
    ms.production_year DESC, 
    ms.actor_count DESC;
