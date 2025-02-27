WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 1990 AND 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast_members,
    AVG(CAST(yy.production_year AS FLOAT)) OVER (PARTITION BY mh.movie_id) AS avg_year_of_related_movies,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS cast_names,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = mh.movie_id) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    aka_title yt ON ci.movie_id = yt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    aka_title yy ON mk.movie_id = yy.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 5
ORDER BY 
    avg_year_of_related_movies DESC, total_cast_members DESC;
