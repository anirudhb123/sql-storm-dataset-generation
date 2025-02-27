WITH ranked_movies AS (
    SELECT 
        mt.title, 
        mp.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        DENSE_RANK() OVER (PARTITION BY mp.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    JOIN 
        title mp ON mt.movie_id = mp.id
    WHERE 
        mp.production_year IS NOT NULL
    GROUP BY 
        mt.title, mp.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    ks.keywords,
    CASE 
        WHEN rm.total_cast > 10 THEN 'Large Cast'
        WHEN rm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.title = ks.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
