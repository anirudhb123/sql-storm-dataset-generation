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
MovieSummary AS (
    SELECT 
        th.title,
        th.production_year,
        COUNT(ci.person_id) AS cast_count,
        MAX(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        STRING_AGG(DISTINCT kw.keyword) AS keywords
    FROM 
        MovieHierarchy th
    LEFT JOIN 
        cast_info ci ON th.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON th.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mw ON th.movie_id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        th.movie_id, th.title, th.production_year
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.has_roles,
    ms.companies,
    ms.keywords,
    RANK() OVER (PARTITION BY ms.production_year ORDER BY ms.cast_count DESC) AS rank_within_year
FROM 
    MovieSummary ms
WHERE 
    ms.cast_count > 5
ORDER BY 
    ms.production_year, ms.cast_count DESC;
