WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS text) AS full_title
    FROM
        aka_title m
    WHERE
        m.production_year = 2023
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.full_title || ' > ' || m.title AS text) AS full_title
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.full_title,
    k.keyword AS keywords,
    a.name AS actor_name,
    ci.kind AS company_type,
    COUNT(DISTINCT ci.id) OVER (PARTITION BY mh.movie_id) AS company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY a.name) AS actor_rank
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
WHERE
    mh.level <= 2 OR ( mh.level = 3 AND c.country_code IS NOT NULL )
ORDER BY
    mh.production_year DESC, mh.level, actor_name NULLS LAST;
