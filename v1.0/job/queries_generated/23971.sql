WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(c.movie_id) OVER (PARTITION BY t.production_year) AS total_cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
co_starring AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS co_stars,
        COUNT(DISTINCT ci.person_id) AS num_co_stars
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_by_title,
    COALESCE(cs.co_stars, 'No Co-Stars') AS co_stars,
    COALESCE(cs.num_co_stars, 0) AS num_co_stars,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.total_cast_members = 0 THEN 'No Cast'
        WHEN rm.total_cast_members > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ranked_movies rm
LEFT JOIN 
    co_starring cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_title <= 3
ORDER BY 
    rm.production_year DESC, rm.rank_by_title;
