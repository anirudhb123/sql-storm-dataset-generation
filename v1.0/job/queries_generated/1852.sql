WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
),
keyword_analysis AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.actors,
    COALESCE(ka.keywords, 'No keywords') AS keywords
FROM 
    high_cast_movies hcm
LEFT JOIN 
    keyword_analysis ka ON hcm.movie_id = ka.movie_id
WHERE 
    hcm.cast_count IS NOT NULL
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC
LIMIT 50;
