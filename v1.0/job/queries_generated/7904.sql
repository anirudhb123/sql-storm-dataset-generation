WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    INNER JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.cast_names
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, rm.movie_id;
