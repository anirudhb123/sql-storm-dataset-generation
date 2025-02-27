WITH movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
movie_info_filtered AS (
    SELECT 
        m.movie_id,
        m.info,
        it.info AS type_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        m.note IS NULL -- Filtering out notes that are not relevant
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
outer_joins_example AS (
    SELECT 
        t.title,
        a.actor_name,
        mc.keywords,
        COALESCE(mi.info, 'No additional info') AS additional_info,
        CASE 
            WHEN mc.total_actors > 5 THEN 'Large Cast'
            WHEN mc.total_actors IS NULL THEN 'No Cast Information'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        title t
    LEFT JOIN 
        movie_cast mc ON t.id = mc.movie_id
    LEFT JOIN 
        movies_with_keywords mw ON t.id = mw.movie_id
    LEFT JOIN 
        movie_info_filtered mi ON t.id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
)
SELECT 
    title,
    actor_name,
    keywords,
    additional_info,
    cast_size
FROM 
    outer_joins_example
WHERE 
    (actor_name IS NOT NULL OR keywords IS NOT NULL) -- Only include rows where either actor or keywords exist
ORDER BY 
    production_year DESC,
    actor_rank ASC NULLS LAST
LIMIT 100;
