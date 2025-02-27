WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        CASE 
            WHEN c.country_code IS NULL THEN 'Unknown Country'
            ELSE c.country_code
        END AS country_code,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind, c.country_code
),

cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

title_keywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ci.company_name,
    ci.company_type,
    ci.country_code,
    ci.total_companies,
    cd.actor_name,
    cd.actor_role,
    cd.actor_order,
    tk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    title_keywords tk ON mh.movie_id = tk.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title, cd.actor_order;
