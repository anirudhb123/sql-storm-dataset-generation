WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title AS title, 
        t.production_year, 
        NULL::text AS parent_title
    FROM
        title t
    JOIN
        aka_title m ON t.id = m.movie_id
    WHERE
        t.production_year IS NOT NULL
   
    UNION ALL

    SELECT 
        m.id AS movie_id, 
        t.title AS title, 
        t.production_year, 
        mh.title AS parent_title
    FROM
        title t
    JOIN
        aka_title m ON t.id = m.movie_id
    JOIN
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT
    p.name,
    COALESCE(cit.kind, 'Unknown Role') AS role,
    mh.title AS movie_title,
    mh.production_year,
    SUM(CASE 
            WHEN ci.nr_order IS NULL THEN 1 
            ELSE 0
        END) AS null_order_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    COUNT(DISTINCT cc.id) OVER (PARTITION BY mh.movie_id) AS cast_count
FROM
    aka_name p
LEFT JOIN 
    cast_info ci ON p.person_id = ci.person_id
LEFT JOIN 
    role_type cit ON ci.role_id = cit.id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id AND cc.status_id = 1
WHERE
    (mh.production_year IS NOT NULL AND mh.production_year > 2000) 
    OR (ci.note IS NOT NULL AND ci.note LIKE '%featured%')
GROUP BY 
    p.name, cit.kind, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, p.name ASC;

