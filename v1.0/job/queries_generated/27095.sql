WITH movie_summary AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT CONCAT(cast.first_name, ' ', cast.last_name), ', ') AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    cast_names,
    keyword_count,
    company_count
FROM 
    movie_summary
WHERE 
    company_count > 10
ORDER BY 
    production_year DESC, movie_title;
