
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastInfoWithRole AS (
    SELECT 
        ci.id,
        ci.movie_id,
        ci.person_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    COALESCE(ciw.role, 'Unknown Role') AS role,
    ciw.role_order,
    ci.num_companies,
    COALESCE(mk.all_keywords, 'No Keywords') AS keywords,
    COALESCE(CAST(mc.production_year AS VARCHAR), 'Unknown Year') AS production_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfoWithRole ciw ON mh.movie_id = ciw.movie_id
LEFT JOIN 
    CompanyInfo ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_title mc ON mh.movie_id = mc.id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.depth <= 3
ORDER BY 
    mh.title, ciw.role_order
LIMIT 50;
