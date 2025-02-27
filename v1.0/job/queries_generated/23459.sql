WITH RecursiveMovieHierarchy AS (
    SELECT 
        m1.id AS movie_id,
        m1.title,
        m1.production_year,
        m2.id AS linked_movie_id,
        m2.title AS linked_title,
        1 AS level
    FROM 
        aka_title m1
    LEFT JOIN 
        movie_link ml ON m1.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m1.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        m2.id AS linked_movie_id,
        m2.title AS linked_title,
        mh.level + 1
    FROM 
        RecursiveMovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m2.production_year IS NOT NULL
)

SELECT 
    rmh.movie_id,
    rmh.title AS original_title,
    rmh.production_year,
    rmh.linked_movie_id,
    rmh.linked_title,
    COALESCE(rmh.level, 0) AS hierarchy_level,
    COUNT(DISTINCT ck.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS average_information_presence
FROM 
    RecursiveMovieHierarchy rmh
LEFT JOIN 
    movie_keyword mk ON rmh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ck ON mk.keyword_id = ck.id
LEFT JOIN 
    movie_info mi ON rmh.movie_id = mi.movie_id
WHERE 
    rmh.production_year BETWEEN 1990 AND 2000
GROUP BY 
    rmh.movie_id, rmh.title, rmh.production_year, rmh.linked_movie_id, rmh.linked_title
HAVING 
    COUNT(DISTINCT ck.keyword) > 0 OR hierarchy_level > 1

ORDER BY 
    average_information_presence DESC, rmh.title ASC;
