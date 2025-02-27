WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM movie_link ml
    INNER JOIN aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY c.movie_id
),

movies_with_companies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mc.total_cast_members, 0) AS total_cast_members,
    COALESCE(mc.cast_names, 'No cast') AS cast_names,
    COALESCE(cn.name, 'No companies') AS company_name,
    COALESCE(ct.kind, 'N/A') AS company_type,
    mh.level,
    CASE 
        WHEN mh.level = 1 THEN 'Original Movie'
        ELSE 'Sequel or Related' 
    END AS movie_relationship
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movies_with_companies mwc ON mh.movie_id = mwc.movie_id
LEFT JOIN 
    company_name cn ON mwc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mwc.company_type = ct.id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, 
    mh.title;
