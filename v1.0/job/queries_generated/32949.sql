WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    CTE.level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(LENGTH(m_info.info)) AS avg_info_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_count
FROM 
    movie_hierarchy CTE
JOIN 
    cast_info ci ON ci.movie_id = CTE.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = CTE.movie_id
LEFT JOIN 
    movie_info m_info ON m_info.movie_id = CTE.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = CTE.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    person_info p ON p.person_id = ak.person_id
GROUP BY 
    ak.name, mt.title, mt.production_year, CTE.level
ORDER BY 
    CTE.level DESC, num_companies DESC;

This query retrieves a hierarchy of movies, their associated actors, and various metrics such as the number of production companies, average information length about each movie, and a count of male and female actors involved. It utilizes a recursive Common Table Expression (CTE) to capture movie links, left joins to incorporate additional details and aggregates various metrics to provide a comprehensive view of performance within the benchmark schema.
