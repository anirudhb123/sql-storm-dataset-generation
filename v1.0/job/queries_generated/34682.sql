WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- consider titles only after the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5 -- limiting depth to prevent deep recursion
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE 
        WHEN mr.rating IS NULL THEN 0
        ELSE mr.rating
    END) AS avg_rating
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        AVG(vote_score) AS rating
     FROM 
        movie_info 
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
        movie_id) mr ON mh.movie_id = mr.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%') -- filtering for drama
GROUP BY 
    ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1 -- having more than one cast member
ORDER BY 
    mh.production_year DESC, total_cast DESC
LIMIT 10;
