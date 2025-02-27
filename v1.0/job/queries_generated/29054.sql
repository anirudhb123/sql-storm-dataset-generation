WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT a.name) AS aka_names,
        ARRAY_AGG(DISTINCT r.role) AS roles
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
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        t.title, t.production_year, c.name, k.keyword
)

SELECT 
    movie_title,
    production_year,
    COUNT(DISTINCT company_name) AS company_count,
    COUNT(DISTINCT movie_keyword) AS keyword_count,
    ARRAY_LENGTH(aka_names, 1) AS aka_name_count,
    ARRAY_LENGTH(roles, 1) AS roles_count
FROM 
    MovieData
WHERE 
    production_year >= 2000
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, movie_title;

This SQL query benchmarks string processing through the usage of various tables to gather complex data related to movies, including associated companies, keywords, and alternate names. It aggregates information to provide insights into the number of companies and keywords associated with each movie and counts the alternate names and roles, filtered by production year.
