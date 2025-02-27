WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rn <= 3
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_companies mc 
     WHERE 
        mc.movie_id = tm.movie_id AND 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')) AS production_companies,
    (SELECT 
        STRING_AGG(DISTINCT cn.name, ', ') 
     FROM 
        movie_companies mc
     JOIN 
        company_name cn ON mc.company_id = cn.id
     WHERE 
        mc.movie_id = tm.movie_id) AS company_names
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
