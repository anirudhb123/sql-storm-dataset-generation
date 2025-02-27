WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
RatedMovies AS (
    SELECT 
        t.title,
        m.production_year,
        COALESCE(COUNT(DISTINCT k.keyword), 0) AS keyword_count,
        SUM(m.info) AS total_info 
    FROM 
        TopMovies t
    JOIN 
        movie_info m ON t.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword k ON t.movie_id = k.movie_id 
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') 
        OR m.info_type_id IS NULL
    GROUP BY 
        t.title, m.production_year
)
SELECT 
    rv.title,
    rv.production_year,
    rv.cast_count,
    rv.keyword_count,
    DENSE_RANK() OVER (PARTITION BY rv.production_year ORDER BY rv.keyword_count DESC) AS rank_by_keywords,
    CASE 
        WHEN rv.cast_count IS NULL THEN 'No Cast Info'
        ELSE TO_CHAR(rv.cast_count) || ' Cast Members'
    END AS cast_description
FROM 
    RatedMovies rv
WHERE 
    (rv.keyword_count > 5 OR rv.cast_count > 0)
ORDER BY 
    rv.production_year DESC, rv.keyword_count DESC;

