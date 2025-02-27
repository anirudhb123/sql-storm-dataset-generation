WITH RECURSIVE MovieHierarchy AS (
    -- Get all movie titles and their immediate linked titles
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    -- Recursively find nested links
    SELECT 
        mh.movie_id,
        mt.title,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

, CastDetails AS (
    -- Get details of casts for each movie
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ct.kind AS role
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
)

, MovieStats AS (
    -- Gather statistics for each movie
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(cd.actor_name) AS actor_count,
        STRING_AGG(DISTINCT cd.role, ', ') AS roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title
)

-- Final output, filtering for movies with more than a certain depth of links and interesting roles
SELECT 
    ms.movie_id,
    ms.title,
    ms.actor_count,
    CASE 
        WHEN ms.actor_count IS NULL THEN 'No Actors'
        WHEN ms.actor_count = 0 THEN 'No Roles Defined'
        ELSE ms.roles
    END AS roles_summary,
    CASE 
        WHEN ms.actor_count > 5 THEN 'Highly Casted Movie'
        ELSE 'Regular Movie'
    END AS movie_type
FROM 
    MovieStats ms
WHERE 
    ms.movie_id IN (SELECT DISTINCT linked_movie_id FROM movie_link WHERE link_type_id IN (SELECT id FROM link_type WHERE link LIKE '%sequel%'))
    OR ms.actor_count IS NULL
ORDER BY 
    ms.actor_count DESC NULLS LAST, 
    ms.title ASC;
