WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title linked ON linked.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = linked.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(ci.id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_actor_names,
    COUNT(DISTINCT mct.kind) FILTER (WHERE c.role_id IS NOT NULL) AS distinct_roles,
    AVG(m.production_year) OVER (PARTITION BY mh.level) AS avg_year_at_level,
    SUM(CASE 
            WHEN LENGTH(COALESCE(ak.name, '')) > 10 THEN 1 
            ELSE 0 
        END) AS long_name_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    role_type rt ON rt.id = ci.role_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    comp_cast_type cct ON cct.id = ci.person_role_id
WHERE 
    mh.production_year IS NOT NULL
    AND mh.production_year > 2010
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    total_cast DESC;
