WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5  -- Limit recursion depth to avoid long chains
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

ImportantRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.company_count,
    cs.company_names,
    ir.actor_count,
    ir.roles,
    CASE 
        WHEN mh.depth IS NOT NULL THEN mh.depth
        ELSE 0
    END AS hierarchy_depth,
    COALESCE(ar.oneshot, 'No') AS one_shot_movie
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CompanyStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    ImportantRoles ir ON mh.movie_id = ir.movie_id
LEFT JOIN (
    SELECT 
        ci.movie_id,
        CASE WHEN MAX(ci.nr_order) = 1 THEN 'Yes' ELSE 'No' END AS oneshot
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) ar ON mh.movie_id = ar.movie_id
WHERE 
    mh.production_year >= 2000
    AND (mh.title ILIKE '%adventure%' OR cs.company_count > 5)
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 100;
