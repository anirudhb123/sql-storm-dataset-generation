WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    WHERE 
        mh.level < 5  -- Limiting depth for hierarchy

), 
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(distinct mk.keyword_id) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

TopMovies AS (
    SELECT 
        f.title,
        f.production_year,
        f.keyword_count,
        RANK() OVER (ORDER BY f.keyword_count DESC) AS rk
    FROM 
        FilteredMovies f
    WHERE 
        f.keyword_count > 0
)

SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    ci.note AS cast_note
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.role_id IS NOT NULL
WHERE 
    tm.rk <= 10  -- Top 10 movies
    AND tm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    tm.keyword_count DESC,
    tm.production_year DESC;
