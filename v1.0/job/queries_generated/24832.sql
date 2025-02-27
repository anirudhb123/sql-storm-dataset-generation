WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS path,
        1 AS level
    FROM aka_title AS mt
    WHERE mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.path || at.title,
        mh.level + 1
    FROM MovieHierarchy AS mh
    JOIN movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN aka_title AS at ON ml.linked_movie_id = at.id
    WHERE mh.level < 5
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(CASE WHEN c.person_role_id IS NULL THEN 1 END) AS uncredited_count,
    STRING_AGG(DISTINCT c.nr_order::text, ', ') AS order_list,
    AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) AS avg_info,
    SUM(CASE 
            WHEN k.keyword IS NOT NULL THEN 1 
            ELSE 0 
        END) AS keyword_count,
    COUNT(DISTINCT mk.id) FILTER (WHERE mk.keyword_id IS NOT NULL) AS distinct_keywords
FROM aka_name AS a
LEFT JOIN cast_info AS c ON a.person_id = c.person_id
LEFT JOIN aka_title AS m ON c.movie_id = m.id
LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%box office%')
LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE a.name IS NOT NULL 
      AND m.production_year IS NOT NULL 
      AND m.kind_id IN (SELECT id FROM kind_type WHERE kind NOT IN ('short', 'tv movie'))
GROUP BY a.id, m.id
HAVING AVG(COALESCE(mi.info::integer, 0)) > 100000
ORDER BY movie_title DESC, actor_name ASC
LIMIT 100;

-- Adding a subquery for further complexity to retrieve related movies that have a keyword starting with "Super"
SELECT 
    m.title,
    ARRAY(SELECT DISTINCT mk.keyword 
          FROM movie_keyword mk 
          JOIN keyword k ON mk.keyword_id = k.id 
          WHERE mk.movie_id = m.id AND k.keyword ILIKE 'Super%') AS relevant_keywords
FROM aka_title m 
WHERE m.id IN (SELECT DISTINCT ml.movie_id FROM movie_link ml JOIN aka_title mt ON ml.linked_movie_id = mt.id)
ORDER BY m.production_year DESC;
