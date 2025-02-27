WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(AVG(pi.info::integer), 0) AS average_awards,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    CASE 
        WHEN COUNT(DISTINCT cc.id) > 10 THEN 'Large Cast'
        WHEN COUNT(DISTINCT cc.id) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY pi.info_id DESC) AS row_num
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    aka_title mt ON cc.movie_id = mt.id
LEFT JOIN 
    movie_info pi ON mt.id = pi.movie_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 2000
    AND (mt.kind_id IN (1, 2, 3) OR mt.production_year < 2010)
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 0
    AND (AVG(pi.info::integer) IS NOT NULL OR AVG(pi.info::integer) IS NULL)
ORDER BY 
    average_awards DESC NULLS LAST,
    total_cast DESC,
    movie_title ASC;

-- Subquery demonstrating corner case with NULL handling
SELECT 
    c.movie_id,
    COUNT(DISTINCT p.id) AS number_of_people,
    COALESCE(MAX(pi.info), 'No Info Available') AS highest_award_info
FROM 
    complete_cast c
LEFT JOIN 
    person_info p ON c.subject_id = p.person_id
LEFT JOIN 
    movie_info pi ON c.movie_id = pi.movie_id
WHERE 
    c.status_id = 1
GROUP BY 
    c.movie_id
HAVING 
    COUNT(DISTINCT p.id) > 1
    AND COALESCE(MAX(pi.info), 'None') <> 'None'
ORDER BY 
    number_of_people DESC;
