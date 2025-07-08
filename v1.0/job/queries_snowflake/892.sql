
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        m.movie_id,
        COUNT(ci.person_role_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.movie_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS info_content
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.cast_count, 0) AS total_cast,
    COALESCE(mc.actor_names, 'No Cast') AS actors,
    mif.info_content AS additional_info
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_filtered mif ON rm.movie_id = mif.movie_id
WHERE 
    rm.year_rank <= 10
    AND (rm.production_year > 2000 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC;
