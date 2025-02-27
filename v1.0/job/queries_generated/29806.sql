WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        co.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        m.production_year >= 2010
        AND k.keyword LIKE '%Action%'
),
AggregatedData AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT person_name || ' (' || person_role || ')', ', ') AS cast_details
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, movie_title, production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    keywords,
    companies,
    cast_details
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;
