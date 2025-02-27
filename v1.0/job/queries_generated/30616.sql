WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedActors AS (
    SELECT 
        ci.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER(PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.person_id, ak.name
)
SELECT 
    m.title,
    COUNT(DISTINCT c.person_id) AS total_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    (SELECT COUNT(*) 
     FROM movie_info mi
     WHERE mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    ) AS budget,
    mh.level
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    RankedActors a ON c.person_id = a.person_id AND a.rank <= 5
GROUP BY 
    m.movie_id, m.title, mh.level
HAVING 
    COUNT(DISTINCT c.person_id) > 3
ORDER BY 
    m.title ASC, mh.level DESC;
