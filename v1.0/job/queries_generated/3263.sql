WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
top_movies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
extensive_info AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        top_movies t
    LEFT JOIN 
        movie_info mi ON t.title = mi.info
    LEFT JOIN 
        movie_companies mc ON t.title = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keywords mk ON t.movie_id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, mk.keywords
)
SELECT 
    ei.title,
    ei.production_year,
    ei.keywords,
    ei.company_names
FROM 
    extensive_info ei
WHERE 
    ei.production_year >= 2000
    AND (ei.keywords LIKE '%action%' OR ei.company_names IS NULL)
ORDER BY 
    ei.production_year DESC;
