WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movies_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(kc.total_keywords, 0) AS total_keywords,
        CASE 
            WHEN rm.production_year < 2000 THEN 'Classic'
            WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_count kc ON rm.movie_id = kc.movie_id
)

SELECT 
    mwi.title,
    mwi.production_year,
    mwi.total_cast,
    mwi.total_keywords,
    mwi.era
FROM 
    movies_with_info mwi
WHERE 
    mwi.total_cast > 10
ORDER BY 
    mwi.production_year DESC, mwi.total_cast DESC;
