WITH RECURSIVE MovieHierarchy AS (
    -- CTE to generate a hierarchy of movies based on linked movies
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieStats AS (
    -- CTE to calculate the average production year by title
    SELECT 
        a.title,
        AVG(a.production_year) AS avg_year,
        COUNT(DISTINCT ca.id) AS cast_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    LEFT JOIN 
        aka_name c ON ca.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title
),
KeywordStats AS (
    -- CTE to analyze keywords per movie, including null checks
    SELECT 
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count,
        MAX(COALESCE(k.keyword, 'No keyword')) AS max_keyword,
        MIN(COALESCE(k.keyword, 'No keyword')) AS min_keyword
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title
)
SELECT 
    mh.title AS movie,
    mh.depth,
    ms.avg_year,
    ms.cast_count,
    ms.cast_names,
    ks.keyword_count,
    ks.max_keyword,
    ks.min_keyword
FROM 
    MovieHierarchy mh
JOIN 
    MovieStats ms ON mh.title = ms.title
JOIN 
    KeywordStats ks ON mh.title = ks.title
ORDER BY 
    mh.depth DESC, ms.avg_year ASC
LIMIT 10;

-- Including NULL logic and peculiar cases for validation
WHERE 
    (mh.depth IS NULL OR mh.depth > 1)
    AND (ms.cast_count > 0 OR ms.cast_names IS NOT NULL);

