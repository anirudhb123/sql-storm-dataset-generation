WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    COALESCE(cm.name, 'Independent') AS company_name,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    DENSE_RANK() OVER (PARTITION BY m.kind_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
GROUP BY 
    m.movie_id, m.title, m.production_year, cm.name
HAVING 
    COUNT(DISTINCT ci.person_id) >= 3
ORDER BY 
    rank_by_cast_count, m.production_year DESC;
