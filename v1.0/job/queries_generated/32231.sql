WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
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
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
),
ActorRoles AS (
    SELECT 
        ca.person_id,
        r.role AS role_name,
        COUNT(ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.person_id, r.role
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(DISTINCT info.info) AS info_texts
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    ar.role_name,
    ar.movie_count AS actor_movie_count,
    cd.company_name,
    cd.company_type,
    cd.company_count,
    mi.info_texts
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.person_id
LEFT JOIN 
    CompanyDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC, 
    ar.movie_count DESC NULLS LAST;
