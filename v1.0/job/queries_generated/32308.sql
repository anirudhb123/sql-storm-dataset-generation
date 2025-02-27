WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (1, 2)  -- Assuming 1: Movie, 2: TV Show
    UNION ALL
    SELECT 
        m.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link m ON mh.movie_id = m.movie_id
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    WHERE 
        mh.depth < 3  -- Limit depth to prevent endless recursion
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ac.cast_count,
    mk.keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_by_title,
    CASE 
        WHEN ac.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_presence
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AggregatedCast ac ON mh.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, 
    mh.title;
