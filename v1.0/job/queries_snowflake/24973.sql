
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
info_summary AS (
    SELECT 
        m.movie_id,
        COUNT(*) AS summary_count 
    FROM 
        movie_info m
    WHERE 
        m.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Summary'
        )
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cd.actor_names, 'None') AS actors,
    COALESCE(isum.summary_count, 0) AS summary_info
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    info_summary isum ON rm.movie_id = isum.movie_id
WHERE 
    rm.rn <= 10 
AND 
    (rm.production_year > 2000 OR cd.actor_count IS NOT NULL)
ORDER BY 
    rm.production_year, rm.title;
