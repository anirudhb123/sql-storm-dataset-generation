WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', m.title)
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.path AS movie_path,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) AS avg_prod_year,
    COUNT(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) FILTER (WHERE c.note IS NULL) AS null_note_cast_count,
    MAX(COALESCE(pi.info, 'No Info Available')) AS person_info
FROM 
    cast_info c
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
INNER JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
INNER JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
INNER JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title at ON c.movie_id = at.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND (at.production_year IS NULL OR at.production_year > 1900)
    AND EXISTS (
        SELECT 1
        FROM movie_info_idx mii
        WHERE mii.movie_id = at.id AND mii.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    )
GROUP BY 
    ak.name, at.title, mh.path
HAVING 
    COUNT(c.id) > 2 AND count(DISTINCT mc.company_id) > 1
ORDER BY 
    avg_prod_year DESC, actor_name
LIMIT 50;
