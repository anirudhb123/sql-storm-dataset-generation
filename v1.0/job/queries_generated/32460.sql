WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    ROUND(AVG(mk.count), 2) AS avg_keywords,
    MAX(tm.rank) AS max_rank
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    (
        SELECT 
            mk.movie_id,
            COUNT(mk.keyword_id) AS count
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank <= 5
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, cn.name
ORDER BY 
    tm.production_year DESC, avg_keywords DESC;

