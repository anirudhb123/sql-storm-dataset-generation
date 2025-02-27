WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3  -- Limit levels to avoid excessive recursion
),
MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_assignments,
        MAX(mi.info) AS movie_note,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.avg_role_assignments,
        ms.movie_note,
        ms.keywords,
        RANK() OVER (ORDER BY ms.cast_count DESC, ms.production_year ASC) AS rank
    FROM 
        MovieStats ms
    WHERE 
        ms.cast_count > 10 AND ms.production_year IS NOT NULL
)
SELECT 
    mh.title AS hierarchy_title,
    mh.production_year,
    tm.title AS top_movie,
    tm.cast_count,
    tm.avg_role_assignments,
    tm.movie_note,
    tm.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopMovies tm ON mh.movie_id = tm.movie_id
WHERE 
    tm.rank IS NOT NULL OR mh.level = 1
ORDER BY 
    mh.level, mh.production_year DESC, tm.cast_count DESC;
