WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        NULL::text AS parent_title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Base case: Top-level movies

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        p.title AS parent_title,
        depth + 1
    FROM 
        aka_title e
    INNER JOIN 
        aka_title p ON e.episode_of_id = p.id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.parent_title,
        mh.depth,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        BOOL_OR(ki.keyword) AS has_keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        mh.movie_id, mh.title, mh.parent_title, mh.depth
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.parent_title,
    ms.depth,
    ms.total_cast,
    ms.total_companies,
    ms.has_keywords,
    ROW_NUMBER() OVER (PARTITION BY ms.depth ORDER BY ms.total_cast DESC) AS rank_by_cast
FROM 
    MovieStats ms
WHERE 
    ms.total_cast > 0 -- Filter out movies with no cast
    AND ms.depth < 3   -- Limit to those that aren't too deeply nested
ORDER BY 
    ms.depth, rank_by_cast;
