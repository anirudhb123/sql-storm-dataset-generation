WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(mci.note, ''), 'No Notes') AS company_note,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mci ON t.id = mci.movie_id
    LEFT JOIN 
        title m ON t.id = m.id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        CONCAT(mh.title, ' (Part ', mh.level + 1, ')') AS nested_title,
        mh.production_year,
        mh.company_note,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)

SELECT 
    a.name AS actor_name,
    Count(DISTINCT c.movie_id) AS movie_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mh.nested_title, ', ') AS related_movies,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
    CASE 
        WHEN c.nr_order IS NULL THEN 'Not Ordered' 
        ELSE 'Ordered: ' || c.nr_order 
    END AS order_status
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    comp_cast_type cct ON c.person_role_id = cct.id
JOIN 
    title m ON m.id = c.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND c.note IS NULL
GROUP BY 
    a.name
ORDER BY 
    movie_count DESC, 
    actor_name
LIMIT 10;
