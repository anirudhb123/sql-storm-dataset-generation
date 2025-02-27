WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        1 AS level,
        mt.title AS title,
        CASE 
            WHEN mt.production_year IS NOT NULL 
            THEN CAST(mt.production_year AS VARCHAR)
            ELSE 'Unknown Year'
        END AS production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        mh.level + 1 AS level,
        et.title AS title,
        CASE 
            WHEN et.production_year IS NOT NULL 
            THEN CAST(et.production_year AS VARCHAR)
            ELSE 'Unknown Year'
        END AS production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON mh.movie_id = et.episode_of_id
)

SELECT 
    mh.level,
    mh.title,
    mh.production_year,
    (SELECT COUNT(DISTINCT c.person_id)
     FROM cast_info c
     WHERE c.movie_id = mh.movie_id) AS actor_count,
    COALESCE((
        SELECT string_agg(DISTINCT a.name, ', ')
        FROM aka_name a
        JOIN cast_info c ON a.person_id = c.person_id
        WHERE c.movie_id = mh.movie_id
    ), 'No Actors') AS actors,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
        )
        THEN (
            SELECT info 
            FROM movie_info mi
            WHERE mi.movie_id = mh.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
        )
        ELSE 'Not Available'
    END AS box_office
FROM 
    movie_hierarchy mh
ORDER BY 
    mh.level, actor_count DESC
LIMIT 100;