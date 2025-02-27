WITH RECURSIVE movie_hierarchy AS (
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
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    WHERE 
        mh.level < 5
),
cast_details AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind IN ('Distributor', 'Production')
),
movie_info_details AS (
    SELECT 
        mi.movie_id, 
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role_type,
    co.company_name,
    co.company_type,
    mid.rating,
    mid.keyword_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    company_details co ON mh.movie_id = co.movie_id
LEFT JOIN 
    movie_info_details mid ON mh.movie_id = mid.movie_id
WHERE 
    mh.production_year = (
        SELECT MAX(mh2.production_year)
        FROM movie_hierarchy mh2
    )
ORDER BY 
    mh.production_year DESC, 
    cd.actor_name;
