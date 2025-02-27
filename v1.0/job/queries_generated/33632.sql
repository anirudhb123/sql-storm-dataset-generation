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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
), 
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
), 
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
movie_info_detailed AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.cast_names,
        cd.company_name,
        cd.company_type,
        cd.total_companies
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        company_details cd ON mh.movie_id = cd.movie_id
),
final_results AS (
    SELECT 
        title,
        production_year,
        total_cast,
        CAST(NULLIF(total_cast, 0) AS FLOAT) / NULLIF(total_companies, 0) AS cast_per_company_ratio
    FROM 
        movie_info_detailed
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    *,
    RANK() OVER (ORDER BY cast_per_company_ratio DESC) AS rank
FROM 
    final_results
WHERE 
    cast_per_company_ratio IS NOT NULL
ORDER BY 
    rank
LIMIT 10;
