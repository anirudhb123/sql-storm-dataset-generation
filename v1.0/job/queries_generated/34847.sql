WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),

CastWithRole AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT ci.id) AS total_roles
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, a.name, r.role
),

UpcomingMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year > 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'N/A') AS primary_actor,
    COALESCE(cwr.role_name, 'N/A') AS primary_role,
    COALESCE(uc.production_companies, 0) AS total_production_companies,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    mh.level
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    CastWithRole AS cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    UpcomingMovies AS uc ON mh.movie_id = uc.movie_id
LEFT JOIN 
    KeywordCounts AS kc ON mh.movie_id = kc.movie_id
ORDER BY 
    mh.production_year DESC,
    total_keywords DESC,
    mh.level,
    mh.title;
