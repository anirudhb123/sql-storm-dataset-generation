WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.title,
    mh.production_year,
    COALESCE(a.name, 'Unknown Actor') AS main_actor,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN cc.kind = 'Lead' THEN 1 ELSE 0 END) AS lead_roles,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS companies,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_company_count
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kc ON mk.keyword_id = kc.id
WHERE
    mh.production_year BETWEEN 1990 AND 2020
    AND kc.keyword IS NOT NULL
GROUP BY
    mh.movie_id, mh.title, mh.production_year, a.name
HAVING
    COUNT(DISTINCT c.id) > 2
ORDER BY
    mh.production_year, rank_by_company_count DESC;
