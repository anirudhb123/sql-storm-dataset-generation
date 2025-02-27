
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

joined_data AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        COALESCE(mk.keywords, ARRAY[]::VARCHAR[]) AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    jd.movie_id,
    jd.title,
    jd.production_year,
    jd.cast_count,
    jd.cast_names,
    jd.keywords,
    CASE 
        WHEN jd.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_era
FROM 
    joined_data jd
ORDER BY 
    jd.production_year DESC, 
    jd.cast_count DESC;
