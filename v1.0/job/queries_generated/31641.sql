WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS depth
    FROM
        aka_title m
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        h.depth + 1
    FROM
        MovieHierarchy h
    JOIN
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
),
CastWithRoleCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS main_cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(CAST(m.production_year AS TEXT), 'Unknown') AS production_year,
        COALESCE(ki.keyword, 'No Keywords') AS movie_keywords
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
),
FinalMovies AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        c.main_cast_count,
        c.cast_names,
        mi.movie_keywords,
        mh.depth
    FROM
        MovieHierarchy mh
    LEFT JOIN
        CastWithRoleCounts c ON mh.movie_id = c.movie_id
    LEFT JOIN
        MovieInfo mi ON mh.movie_id = mi.movie_id
)

SELECT
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.main_cast_count,
    f.cast_names,
    f.movie_keywords,
    f.depth,
    CASE 
        WHEN f.depth = 0 THEN 'Main Movie'
        ELSE 'Linked Movie'
    END AS movie_type
FROM
    FinalMovies f
WHERE
    (f.production_year IS NOT NULL AND f.production_year >= 2000) 
    OR f.cast_names IS NOT NULL
ORDER BY
    f.depth, f.production_year DESC;
