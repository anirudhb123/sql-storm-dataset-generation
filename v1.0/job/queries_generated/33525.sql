WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.role_id) AS role_count,
        RANK() OVER (ORDER BY COUNT(ci.role_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(ci.role_id) > 0
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(classifications.classification, 'Unclassified') AS classification,
    tm.role_count
FROM 
    TopMovies tm
LEFT JOIN (
    SELECT 
        mt.movie_id,
        CASE 
            WHEN kw.keyword IS NOT NULL THEN 'Has Keywords'
            ELSE 'No Keywords'
        END AS classification
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
) AS classifications ON tm.movie_id = classifications.movie_id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
