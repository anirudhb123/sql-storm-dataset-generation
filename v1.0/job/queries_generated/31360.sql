WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM title mt
    WHERE mt.episode_of_id IS NULL -- Get top-level movies

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        et.episode_of_id
    FROM title et
    INNER JOIN MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        COALESCE(mi.info, 'No information available') AS movie_notes
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    GROUP BY m.id, m.title, m.production_year
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    md.actor_name,
    md.role,
    md.role_order,
    mi.keyword_count,
    mi.movie_notes,
    CASE 
        WHEN md.role_order IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_presence,
    COUNT(*) OVER (PARTITION BY mh.movie_id) AS total_roles
FROM MovieHierarchy mh
LEFT JOIN CastDetails md ON mh.movie_id = md.movie_id
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id
ORDER BY mh.production_year DESC, mh.level, mh.title, md.role_order;
