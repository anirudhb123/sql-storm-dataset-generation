WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_roles AS (
    SELECT 
        ai.person_id,
        ct.kind AS role_type,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ai.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ct.id = ci.role_id
    GROUP BY 
        ai.person_id, ct.kind
    HAVING 
        COUNT(ci.id) > 1
),
company_partners AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COALESCE(ar.role_count, 0) AS actor_role_count,
    ar.role_type,
    COALESCE(cp.companies, 'No Companies') AS companies_produced,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_roles ar ON ar.person_id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = mh.movie_id
    )
LEFT JOIN 
    company_partners cp ON cp.movie_id = mh.movie_id
LEFT JOIN 
    movies_with_keywords mk ON mk.movie_id = mh.movie_id
WHERE 
    mh.production_year >= (SELECT AVG(production_year) FROM aka_title)
    AND (mk.keywords IS NOT NULL OR cp.companies IS NOT NULL)
ORDER BY 
    mh.production_year DESC, mh.level ASC
LIMIT 100;
