WITH MovieData AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        p.name AS person_name,
        k.keyword AS movie_keyword,
        r.role AS person_role
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND c.country_code = 'USA'
),
AggregatedData AS (
    SELECT 
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT person_name, ', ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieData
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    title,
    production_year,
    companies,
    actors,
    keywords
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, title;
