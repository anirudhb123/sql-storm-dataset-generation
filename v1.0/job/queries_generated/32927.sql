WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS a ON a.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Production') AS production_company_count,
    COALESCE(MIN(mvinfo.info), 'No information available') AS movie_info
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info AS c ON c.movie_id = cc.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword AS k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_type AS ct ON ct.id = mc.company_type_id
LEFT JOIN 
    movie_info AS mvinfo ON mvinfo.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (mh.title ILIKE '%action%' OR mh.title ILIKE '%adventure%')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY 
    mh.depth DESC, actor_count DESC
LIMIT 50;
