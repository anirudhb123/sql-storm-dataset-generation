WITH RECURSIVE MovieHierarchy AS (
    -- CTE to recursively find all linked movies in a "franchise" or series
    SELECT 
        m.id AS movie_id,
        t.title,
        ARRAY[m.id] AS linked_movies
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id

    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title,
        mh.linked_movies || m.id
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        NOT m.id = ANY(mh.linked_movies) -- prevent cycles
),
AggMovieInfo AS (
    -- Aggregate info of movies including genres, keywords and number of actors
    SELECT 
        th.id AS movie_id,
        th.title,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(COALESCE(mo.info, 'N/A')) AS movie_note
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title th ON mh.movie_id = th.id
    LEFT JOIN 
        movie_keyword mk ON th.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info ci ON th.id = ci.movie_id
    LEFT JOIN 
        movie_info mo ON th.id = mo.movie_id
    GROUP BY 
        th.id, th.title
)
SELECT 
    a.movie_id,
    a.title,
    a.keywords,
    a.actor_count,
    CASE 
        WHEN a.actor_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS movie_status,
    CASE 
        WHEN ARRAY_LENGTH(mh.linked_movies, 1) IS NULL THEN 'Standalone'
        ELSE 'Part of a Series'
    END AS movie_franchise
FROM 
    AggMovieInfo a
LEFT JOIN 
    MovieHierarchy mh ON a.movie_id = mh.movie_id
ORDER BY 
    a.actor_count DESC, a.title ASC;
