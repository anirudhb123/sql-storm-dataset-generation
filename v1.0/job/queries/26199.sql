WITH movie_summary AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        p.name AS person_name,
        r.role AS role_name,
        COUNT(DISTINCT ca.id) AS cast_count
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
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        name p ON ca.person_id = p.id
    JOIN 
        role_type r ON ca.role_id = r.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
        AND k.keyword IS NOT NULL
    GROUP BY 
        a.title, a.production_year, c.name, k.keyword, p.name, r.role
    ORDER BY 
        a.production_year DESC, cast_count DESC
    LIMIT 100
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(person_name, ' as ', role_name), ', ') AS cast_list,
    cast_count
FROM 
    movie_summary
GROUP BY 
    movie_title, production_year, cast_count
ORDER BY 
    production_year DESC, cast_count DESC;
