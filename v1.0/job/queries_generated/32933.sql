WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

ActorRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT ca.id) AS number_of_roles
    FROM 
        cast_info ca
    JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.person_id, ca.movie_id
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

CompanyParticipation AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ar.roles, 'No roles assigned') AS roles,
    COALESCE(ar.number_of_roles, 0) AS number_of_roles,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(cp.company_count, 0) AS company_count,
    COALESCE(cp.company_names, 'No companies') AS company_names,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    KeywordCounts kc ON mh.movie_id = kc.movie_id
LEFT JOIN 
    CompanyParticipation cp ON mh.movie_id = cp.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.depth ASC, 
    mh.title;
