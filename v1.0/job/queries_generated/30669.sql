WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.production_year >= 2000
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_role_id) AS role_count,
        STRING_AGG(DISTINCT CONVERT(VARCHAR, r.role), ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieCompanyTypes AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name,
        COUNT(ci.person_id) AS num_movies
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(ci.person_id) > 2
),
FinalResult AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cr.role_count, 0) AS unique_roles,
        COALESCE(mct.company_count, 0) AS company_count,
        COALESCE(ta.num_movies, 0) AS featured_actors
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithRoles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        MovieCompanyTypes mct ON mh.movie_id = mct.movie_id
    LEFT JOIN 
        TopActors ta ON mh.movie_id = ta.movie_id
    WHERE 
        mh.level <= 3
)
SELECT 
    title,
    production_year,
    unique_roles,
    company_count,
    featured_actors
FROM 
    FinalResult
ORDER BY 
    production_year DESC, title;
