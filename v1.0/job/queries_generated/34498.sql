WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title ep
    JOIN 
        movie_hierarchy mh ON ep.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        ak.name,
        c.nr_order,
        rt.role
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mci.person_id) AS total_people
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mci ON mc.movie_id = mci.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    mh.title,
    mh.production_year,
    mh.level,
    cd.name AS cast_member,
    cd.role,
    mci.company_name,
    mci.total_people,
    COUNT(mk.keyword) AS keyword_count,
    STRING_AGG(mk.keyword, ', ') AS keyword_list
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_company_info mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, cd.name, cd.role, mci.company_name, mci.total_people
ORDER BY 
    mh.production_year DESC, mh.level, cd.nr_order;
