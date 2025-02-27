
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        rv.role AS role_type
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rv ON ci.role_id = rv.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),

KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT movie_keyword) AS unique_keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    kc.unique_keywords,
    STRING_AGG(DISTINCT md.person_name, ', ') AS cast_names,
    STRING_AGG(DISTINCT md.company_name, ', ') AS companies_involved
FROM 
    MovieDetails md
JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, kc.unique_keywords
ORDER BY 
    kc.unique_keywords DESC, md.production_year DESC;
