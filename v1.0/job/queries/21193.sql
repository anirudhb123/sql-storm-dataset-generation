WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        0 AS level 
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.season_nr IS NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

, CastDetails AS (
    SELECT 
        c.person_id,
        c.movie_id,
        COALESCE(a.name, '') || ' as ' || COALESCE(r.role, 'Unknown Role') AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
)

, MovieSummary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT cd.person_id) AS actor_count,
        MAX(CASE WHEN c.production_year IS NOT NULL THEN c.production_year ELSE 0 END) AS max_year,
        STRING_AGG(DISTINCT cd.actor_role, ', ') AS actors_in_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN aka_title c ON mh.movie_id = c.id
    GROUP BY 
        mh.movie_id, mh.title
)

SELECT 
    ms.movie_id, 
    ms.title, 
    ms.actor_count,
    ms.max_year,
    COALESCE(ms.actors_in_roles, 'No Actors') AS actors_in_roles,
    CASE 
        WHEN ms.actor_count > 10 THEN 'Star-studded' 
        WHEN ms.actor_count BETWEEN 5 AND 10 THEN 'Notable' 
        ELSE 'Few Actors'
    END AS movie_rating
FROM 
    MovieSummary ms
WHERE 
    ms.max_year > 2000
ORDER BY 
    ms.actor_count DESC NULLS LAST,
    ms.title ASC;
