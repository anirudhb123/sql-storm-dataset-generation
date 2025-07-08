
WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank_within_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),

movie_keywords AS (
    SELECT 
        ak.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword ak
    JOIN
        keyword k ON ak.keyword_id = k.id
    GROUP BY 
        ak.movie_id
),

top_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        mk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
    WHERE 
        rm.rank_within_year <= 5 
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(tm.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_desc
FROM 
    top_movies tm
LEFT JOIN 
    movie_info mi ON (mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) AND mi.note IS NOT NULL)
WHERE 
    EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1) AND mc.company_id IS NOT NULL)
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC
LIMIT 20;
