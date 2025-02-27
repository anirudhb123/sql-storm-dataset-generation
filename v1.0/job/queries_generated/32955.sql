WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        ak.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ak.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(cast.member_count, 0) AS total_cast,
    STRING_AGG(DISTINCT co.name, ', ') AS companies,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS rank
FROM 
    movie_hierarchy mh
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS member_count
    FROM 
        cast_info
    GROUP BY 
        movie_id
) cast ON cast.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cast.member_count
ORDER BY 
    mh.production_year DESC, rank
LIMIT 100;
