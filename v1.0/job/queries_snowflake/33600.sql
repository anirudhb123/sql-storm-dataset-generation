
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level
    FROM 
        title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(p.name, 'Unknown') AS person_name,
    r.role AS persons_role,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(rw.rank) AS avg_rank,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT 
         id, 
         ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY id DESC) AS rank 
     FROM 
         complete_cast) rw ON rw.id = cc.id
WHERE 
    m.production_year >= 2000 
GROUP BY 
    m.movie_id, m.title, m.production_year, p.name, r.role
ORDER BY 
    total_cast DESC, m.title;
