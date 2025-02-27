
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COUNT(DISTINCT mi.info) AS info_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ARRAY_AGG(DISTINCT cn.name) AS company_names
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, info_count DESC;
