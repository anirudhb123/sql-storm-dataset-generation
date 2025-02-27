WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        m.season_nr,
        m.episode_nr,
        ARRAY[m.id] AS hierarchy_path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1 AS level,
        m.season_nr,
        m.episode_nr,
        h.hierarchy_path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy h ON m.episode_of_id = h.movie_id
),

cast_details AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order,
        COALESCE(NULLIF(a.name_pcode_cf, ''), 'UNKNOWN') AS pcode 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),

movies_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ARRAY_AGG(DISTINCT cd.actor_name) AS actors,
        COUNT(DISTINCT cd.person_id) AS num_actors,
        MAX(mo.info) FILTER (WHERE it.info = 'rating') AS highest_rating
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info mo ON mh.movie_id = mo.movie_id
    LEFT JOIN 
        info_type it ON mo.info_type_id = it.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

final_selection AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.actors,
        mi.num_actors,
        CASE 
            WHEN mi.num_actors > 10 THEN 'More than 10 actors'
            WHEN mi.num_actors = 0 THEN 'No actors'
            ELSE 'Moderate number of actors'
        END AS actor_category,
        COALESCE(mi.highest_rating, 'Not Rated') AS rating
    FROM 
        movies_info mi
    WHERE 
        mi.production_year > 1990 
        AND mi.num_actors > 2
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actors,
    f.num_actors,
    f.actor_category,
    f.rating
FROM 
    final_selection f
ORDER BY 
    f.production_year DESC,
    f.num_actors DESC,
    f.title ASC;
