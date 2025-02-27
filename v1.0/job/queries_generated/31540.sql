WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(ka.name, ', ') AS actor_names,
        COUNT(ci.person_role_id) AS actor_count
    FROM 
        cast_info ci
    JOIN aka_name ka ON ka.person_id = ci.person_id
    GROUP BY ci.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mi.info, 'No Additional Info') AS additional_info
    FROM 
        aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.actor_names, 'No Cast') AS actor_names,
    cd.actor_count,
    COALESCE(mi.additional_info, 'No Info') AS additional_info,
    COALESCE(mcd.companies, 'No Companies') AS companies,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON mh.movie_id = mcd.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;
