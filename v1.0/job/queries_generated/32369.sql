WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, MovieRating AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS avg_rating
    FROM 
        movie_info m
    JOIN 
        movie_keyword k ON m.movie_id = k.movie_id
    JOIN 
        rating r ON k.keyword_id = r.keyword_id
    GROUP BY 
        m.id
)
SELECT 
    DISTINCT 
        a.name AS actor_name,
        t.title AS movie_title,
        c.kind AS company_type,
        mh.movie_title AS related_movie,
        COALESCE(mr.avg_rating, 0) AS avg_rating,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mr.avg_rating DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    MovieRating mr ON mr.movie_id = t.id
WHERE 
    c.kind IS NOT NULL
    AND t.production_year BETWEEN 2010 AND 2023
    AND mh.level <= 2
ORDER BY 
    actor_name, avg_rating DESC;
