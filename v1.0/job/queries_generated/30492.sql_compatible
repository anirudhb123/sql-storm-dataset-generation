
WITH RECURSIVE movie_hierarchy AS (
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
        mm.id AS movie_id,
        mm.title AS movie_title,
        mm.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    WHERE 
        mh.level < 5
)
SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE 
        WHEN mci.note IS NOT NULL THEN 1 
        ELSE 0
    END) AS has_company_note,
    ROW_NUMBER() OVER (PARTITION BY mt.movie_id ORDER BY mt.production_year DESC) AS rank
FROM 
    movie_hierarchy mt
JOIN 
    complete_cast cc ON mt.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mci ON mt.movie_id = mci.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mt.production_year >= 2000
GROUP BY 
    ak.name, mt.movie_title, mt.production_year, mt.movie_id
HAVING 
    COUNT(DISTINCT c.id) > 3
ORDER BY 
    total_cast DESC, mt.production_year ASC
LIMIT 10;
