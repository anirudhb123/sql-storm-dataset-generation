WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
RankedMovies AS (
    SELECT
        mv.title,
        mv.production_year,
        COUNT(cc.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mv.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank_within_year
    FROM
        MovieHierarchy mv
    LEFT JOIN
        complete_cast cc ON mv.movie_id = cc.movie_id
    GROUP BY
        mv.title, mv.production_year
    HAVING
        COUNT(cc.person_id) > 0
),
ActorsWithRoles AS (
    SELECT
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        a.name, rt.role
    HAVING
        COUNT(*) > 1
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    awr.actor_name,
    awr.role_name,
    awr.role_count
FROM 
    RankedMovies rm
JOIN 
    ActorsWithRoles awr ON awr.role_count >= 2
WHERE 
    rm.rank_within_year <= 5   -- Top 5 movies in terms of cast count each year
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
