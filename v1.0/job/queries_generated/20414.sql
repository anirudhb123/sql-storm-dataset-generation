WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS level,
           NULL::integer AS parent_id
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id,
           mt.title,
           mt.production_year,
           mh.level + 1,
           mh.movie_id
    FROM movie_link ml
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
    JOIN aka_title mt ON mt.id = ml.linked_movie_id
    WHERE ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
)

SELECT
    aka_person.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COALESCE(SUM(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END)::FLOAT / NULLIF(COUNT(ci.id), 0), 0) AS retention_rate,
    COUNT(DISTINCT mv.keyword) AS keyword_count,
    STRING_AGG(DISTINCT COALESCE(kw.keyword, 'Unknown') || ' (' || kk.kind || ')', ', ' ORDER BY kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY COUNT(ci.id) DESC) AS actor_rank
FROM 
    aka_name aka_person
JOIN 
    cast_info ci ON ci.person_id = aka_person.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    movie_keyword mv ON mv.movie_id = at.id
LEFT JOIN 
    keyword kw ON kw.id = mv.keyword_id
LEFT JOIN 
    kind_type kk ON kk.id = at.kind_id
WHERE 
    mh.level = 0
    AND EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = at.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') AND mi.info::NUMERIC > 1000000)
GROUP BY 
    aka_person.name, 
    at.title, 
    mh.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    retention_rate DESC, actor_rank
LIMIT 50;
