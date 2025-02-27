WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY[mt.title] AS title_path,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Start with titles from the year 2000 onwards
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.title_path || at.title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 5 -- Limit to a maximum depth of 5
),
CastInformation AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieWithDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        STRING_AGG(ci.actor_name || ' (' || ci.role || ')', ', ') AS actors,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInformation ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mh.movie_id, mh.title
)
SELECT 
    mw.title,
    mw.actors,
    mw.keyword_count,
    COALESCE(NULLIF(mw.keyword_count, 0), 'No keywords') AS keyword_info,
    CASE 
        WHEN mw.keyword_count > 0 THEN 'Has Keywords'
        ELSE 'No Keywords Found'
    END AS keyword_status
FROM 
    MovieWithDetails mw
ORDER BY 
    mw.keyword_count DESC, 
    mw.title ASC;

