WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.title,
        mt.production_year,
        mt.id AS movie_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
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
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.role_name,
    mk.keywords,
    mc.companies,
    mc.company_types,
    COUNT(cd.actor_name) OVER (PARTITION BY mh.movie_id) AS total_cast,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Early'
        ELSE 'Recent'
    END AS movie_age
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON mh.movie_id = mc.movie_id
WHERE 
    cd.actor_order <= 3 OR cd.actor_order IS NULL
ORDER BY 
    mh.production_year DESC, mh.title;
