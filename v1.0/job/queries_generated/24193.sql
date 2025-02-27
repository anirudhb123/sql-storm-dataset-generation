WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CASE 
            WHEN m.episode_of_id IS NOT NULL THEN 'Episode'
            ELSE 'Movie' 
        END AS type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        'Linked' AS type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC)
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
, top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.type,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        mh.rank = 1 -- Getting the latest hierarchy for each movie
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.type
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.type,
    tm.actor_count,
    tm.actor_names,
    CASE 
        WHEN tm.actor_count > 5 THEN 'Blockbuster' 
        WHEN tm.actor_count BETWEEN 3 AND 5 THEN 'Popular' 
        ELSE 'Indie' 
    END AS classification
FROM 
    top_movies tm
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = tm.movie_id 
          AND mi.info LIKE '%Award%'
    )
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
