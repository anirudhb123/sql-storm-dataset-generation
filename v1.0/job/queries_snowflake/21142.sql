
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.year_rank <= 5
),
keyword_movies AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    k.keywords,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM 
    high_cast_movies hcm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = hcm.title_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    keyword_movies k ON hcm.title_id = k.movie_id
WHERE 
    hcm.production_year IS NOT NULL
AND 
    (cn.country_code IN ('US', 'UK') OR cn.country_code IS NULL)
AND 
    (k.keywords IS NOT NULL OR k.keywords IS NOT NULL)
ORDER BY 
    hcm.production_year DESC,
    hcm.title;
