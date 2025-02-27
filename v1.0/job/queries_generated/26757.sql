WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        k.keyword AS movie_keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.phonetic_code IS NOT NULL
), 
ActorRoles AS (
    SELECT 
        ka.name AS actor_name,
        mt.title AS movie_title,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ct.kind = 'lead'
), 
CompanyMovies AS (
    SELECT 
        cn.name AS company_name,
        mt.title AS movie_title,
        mt.production_year
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    WHERE 
        cn.country_code IN ('USA', 'CAN') 
)
SELECT 
    mh.movie_title,
    mh.production_year,
    ARRAY_AGG(DISTINCT mk.movie_keyword) AS keywords,
    ARRAY_AGG(DISTINCT ar.actor_name || ' (' || ar.role_name || ')') AS actors,
    ARRAY_AGG(DISTINCT cm.company_name) AS production_companies
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON mh.movie_title = ar.movie_title
LEFT JOIN 
    CompanyMovies cm ON mh.movie_title = cm.movie_title
GROUP BY 
    mh.movie_title, mh.production_year
ORDER BY 
    mh.production_year DESC, mh.movie_title;
