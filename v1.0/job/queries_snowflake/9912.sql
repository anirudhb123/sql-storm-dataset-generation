
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS role,
        t.id AS movie_id
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
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
KeywordCount AS (
    SELECT 
        md.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        MovieDetails md ON mk.movie_id = md.movie_id
    GROUP BY 
        md.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.person_name,
    md.role,
    kc.keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
ORDER BY 
    md.production_year DESC, 
    kc.keyword_count DESC;
