WITH RECURSIVE MovieHierarchy AS (
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
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
CompanyContributions AS (
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
        cn.country_code IS NOT NULL
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
    COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.role, 'N/A') AS role,
    COALESCE(cc.company_name, 'Independent') AS company_name,
    COALESCE(cc.company_type, 'N/A') AS company_type,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    CompanyContributions cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.title,
    mh.level,
    ar.actor_rank;
