WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.total_cast,
    COALESCE(ARRAY_AGG(DISTINCT a.name), '{}') AS actors,
    COALESCE(ARRAY_AGG(DISTINCT c.name), '{}') AS companies
FROM 
    ranked_movies r
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    r.movie_id, r.title, r.production_year, r.total_cast
ORDER BY 
    r.total_cast DESC;
