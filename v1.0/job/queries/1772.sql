
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order,
        t.id AS movie_id
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
),
CompanyStats AS (
    SELECT 
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.name, ct.kind
)
SELECT 
    md.title,
    md.production_year,
    ai.actor_name,
    ai.movie_count,
    cs.company_name,
    cs.company_type,
    cs.total_movies
FROM 
    MovieDetails md
JOIN 
    ActorInfo ai ON md.movie_id = ai.movie_count
LEFT JOIN 
    CompanyStats cs ON md.production_year = 2020
WHERE 
    md.keyword IS NOT NULL
    AND (LOWER(md.title) LIKE '%adventure%' OR md.production_year > 2015)
ORDER BY 
    md.production_year DESC, ai.movie_count DESC;
