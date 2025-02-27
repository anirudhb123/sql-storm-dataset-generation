
WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS keyword,
        p.info AS person_info,
        r.role AS role_name
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name n ON ci.person_id = n.id
    JOIN 
        person_info p ON n.id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year >= 2000
        AND c.country_code = 'USA'
),
AggregatedData AS (
    SELECT 
        movie_title,
        a.production_year,
        COUNT(DISTINCT company_name) AS num_companies,
        COUNT(DISTINCT keyword) AS num_keywords,
        STRING_AGG(DISTINCT role_name, ', ') AS roles,
        STRING_AGG(DISTINCT person_info, '; ') AS person_infos
    FROM 
        MovieDetails a
    GROUP BY 
        movie_title, a.production_year
)
SELECT 
    movie_title,
    production_year,
    num_companies,
    num_keywords,
    roles
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, num_keywords DESC;
