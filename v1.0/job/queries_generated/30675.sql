WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RoleDetails AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    mh.production_year,
    rd.role,
    rd.total_actors,
    ci.company_name,
    ci.company_type,
    mk.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RoleDetails rd ON mh.movie_id = rd.movie_id
LEFT JOIN 
    CompanyInfo ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = 1
    AND (rd.total_actors IS NULL OR rd.total_actors > 5)
ORDER BY 
    mh.production_year DESC, mh.title;
