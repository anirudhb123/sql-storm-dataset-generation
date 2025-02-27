WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword,
        cn.name AS company_name,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword, cn.name
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword,
    rm.company_name,
    rm.cast_count
FROM 
    ranked_movies rm
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 100;
