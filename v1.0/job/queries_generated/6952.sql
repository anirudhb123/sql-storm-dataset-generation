WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        pk.keyword,
        cn.name AS company_name,
        c.role_id
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS pk ON mk.keyword_id = pk.id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        role_type AS r ON ci.role_id = r.id
)

SELECT 
    COUNT(*) AS total_movies,
    AVG(md.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM 
    MovieDetails AS md
GROUP BY 
    md.production_year
HAVING 
    COUNT(DISTINCT md.movie_id) > 1
ORDER BY 
    avg_production_year DESC;
