WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
  
    UNION ALL
  
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies,
        COUNT(DISTINCT mc.company_id) AS unique_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, company_name, company_type
),

KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_movies, 0) AS total_movies_by_company,
    COALESCE(cs.unique_companies, 0) AS unique_companies,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year) AS year_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CompanyStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    KeywordCounts kc ON mh.movie_id = kc.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC,
    mh.title;
