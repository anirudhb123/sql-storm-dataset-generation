WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.id] AS movie_path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_ranked AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IS NOT NULL
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ak.name AS actor_name,
    CASE 
        WHEN kr.keyword_count IS NOT NULL THEN kr.keyword_count 
        ELSE 0 
    END AS number_of_keywords,
    COUNT(DISTINCT cc.company_id) AS company_count,
    COUNT(DISTINCT ctv.role_id) AS distinct_roles,
    MAX(CASE WHEN rt.role = 'Director' THEN ci.nr_order END) AS director_rank

FROM 
    movie_hierarchy mh
JOIN 
    cast_ranked ctv ON mh.movie_id = ctv.movie_id
JOIN 
    aka_name ak ON ctv.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    keyword_stats kr ON mh.movie_id = kr.movie_id
LEFT JOIN 
    comp_cast_type cct ON ctv.role_id = cct.id
LEFT JOIN 
    role_type rt ON ctv.role_id = rt.id

WHERE 
    mh.production_year > 1990
    AND ak.name IS NOT NULL
    AND (kr.keyword_count IS NULL OR kr.keyword_count > 1)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ak.name, kr.keyword_count
ORDER BY 
    mh.production_year DESC, number_of_keywords DESC, director_rank DESC
FETCH FIRST 10 ROWS ONLY;
