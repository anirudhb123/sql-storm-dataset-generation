WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT cc.id) AS total_cast_members,
    AVG(mv.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN AVG(mv.production_year) IS NOT NULL THEN
            CASE 
                WHEN AVG(mv.production_year) < 2000 THEN 'Classic'
                WHEN AVG(mv.production_year) BETWEEN 2000 AND 2010 THEN 'Modern'
                ELSE 'Recent'
            END
        ELSE 'Unknown Era'
    END AS classification,
    SUM(CASE 
        WHEN p.info IS NULL THEN 1 
        ELSE 0 
    END) AS unresolved_info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS row_num
FROM 
    cast_info cc
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info p ON cc.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Bio')
GROUP BY 
    ak.name, mt.title
HAVING 
    COUNT(DISTINCT cc.id) > 5 AND AVG(mv.production_year) IS NOT NULL
ORDER BY 
    avg_production_year DESC
LIMIT 10;
