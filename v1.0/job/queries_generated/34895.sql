WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
),
PersonalInfo AS (
    SELECT 
        pi.person_id,
        MAX(pi.info) AS latest_info
    FROM 
        person_info AS pi
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%career%')
    GROUP BY 
        pi.person_id
),
TopMovies AS (
    SELECT 
        title.id,
        title.title,
        COUNT(DISTINCT cast.person_id) AS total_cast
    FROM 
        title 
    LEFT OUTER JOIN 
        cast_info AS cast ON title.id = cast.movie_id
    GROUP BY 
        title.id
    HAVING 
        COUNT(DISTINCT cast.person_id) > 10
),
MoviesWithInfo AS (
    SELECT 
        tm.id,
        tm.title,
        tm.total_cast,
        mh.depth,
        CASE 
            WHEN mh.movie_id IS NOT NULL THEN 'Linked'
            ELSE 'Standalone'
        END AS movie_status
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieHierarchy mh ON tm.id = mh.movie_id
)
SELECT 
    mwi.title,
    mwi.total_cast,
    mwi.depth,
    mwi.movie_status,
    pi.latest_info
FROM 
    MoviesWithInfo mwi
LEFT JOIN 
    PersonalInfo pi ON pi.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = mwi.id)
WHERE 
    mwi.depth < 3
ORDER BY 
    mwi.total_cast DESC,
    mwi.depth ASC;
