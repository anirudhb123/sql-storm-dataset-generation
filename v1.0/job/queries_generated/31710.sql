WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Top level movies (not episodes)
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
CompanyRoles AS (
    SELECT 
        cc.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        mc.movie_id
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT info.info, '; ') AS info_details,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        PersonRoles ci ON mi.movie_id = ci.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Rating', 'Box Office'))
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(pr.actor_name, 'Unknown') AS lead_actor,
    CTE.company_name,
    CTE.company_type,
    MI.keywords,
    MI.info_details,
    MI.total_cast,
    CASE 
        WHEN mi.info IS NULL THEN 'No information available'
        ELSE mi.info
    END AS additional_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CompanyRoles CTE ON mh.movie_id = CTE.movie_id
LEFT JOIN 
    MovieInfo MI ON mh.movie_id = MI.movie_id
LEFT JOIN 
    PersonRoles pr ON mh.movie_id = pr.movie_id AND pr.role_order = 1  -- Get the first role (lead actor)
ORDER BY 
    mh.level, mh.title;
