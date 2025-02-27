WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.id] AS movie_path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start from root movies
    UNION ALL
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_path || et.id
    FROM 
        aka_title et
    INNER JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),
cast_with_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT cwr.role_name) AS roles,
    mci.company_name,
    mci.company_type,
    mci.company_count,
    COUNT(DISTINCT cwr.person_id) AS total_cast,
    STRING_AGG(DISTINCT CASE 
        WHEN cwr.role_order = 1 THEN CONCAT(name.name, ' as ', cwr.role_name) 
        ELSE NULL 
    END, ', ') AS lead_actors
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_roles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    movie_company_info mci ON mh.movie_id = mci.movie_id
LEFT JOIN 
    aka_name name ON cwr.person_id = name.person_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.id, mci.company_name, mci.company_type, mci.company_count
ORDER BY 
    mh.production_year DESC, mh.title;
