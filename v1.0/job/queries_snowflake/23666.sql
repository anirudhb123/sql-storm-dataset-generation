WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
missing_cast AS (
    SELECT 
        at.title,
        at.production_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        ci.id IS NULL
),
mojo AS (
    SELECT 
        at.title,
        MAX(mi.info) AS max_rating
    FROM 
        aka_title at
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        at.title
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mc.title, 'No Cast') AS missing_cast_title,
    COALESCE(rm.rank_within_year, 0) AS rank_within_year,
    COALESCE(mo.max_rating, 'Not Rated') AS max_rating
FROM 
    ranked_movies rm
FULL OUTER JOIN 
    missing_cast mc ON rm.title = mc.title AND rm.production_year = mc.production_year
LEFT JOIN 
    mojo mo ON rm.title = mo.title
WHERE 
    (rm.cast_count IS NULL OR rm.cast_count > 5) 
    AND (mo.max_rating IS NULL OR mo.max_rating > '5.0')
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC NULLS LAST;

