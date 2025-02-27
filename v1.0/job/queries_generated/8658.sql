WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.company_names,
        rm.keywords
    FROM 
        ranked_movies rm
    WHERE 
        rm.cast_count > 10
)
SELECT 
    hcm.movie_id,
    hcm.movie_title,
    hcm.production_year,
    hcm.cast_count,
    unnest(hcm.company_names) AS company_name,
    unnest(hcm.keywords) AS keyword
FROM 
    high_cast_movies hcm
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
