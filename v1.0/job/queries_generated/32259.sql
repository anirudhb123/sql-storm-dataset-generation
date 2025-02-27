WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
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
    cha.name AS character_name,
    ak.name AS alias_name,
    m.movie_title,
    m.production_year,
    COALESCE(COUNT(DISTINCT cm.company_id), 0) AS company_count,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_role_order,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY m.movie_title) AS title_rank
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
JOIN 
    char_name cha ON cha.id = cc.subject_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id AND ci.person_id = ak.person_id
GROUP BY 
    cha.name, ak.name, m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0 
ORDER BY 
    m.production_year DESC, title_rank ASC;
