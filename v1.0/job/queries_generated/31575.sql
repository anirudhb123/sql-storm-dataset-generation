WITH RECURSIVE CompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
          
    UNION ALL

    SELECT 
        ch.movie_id,
        ch.company_name,
        ch.company_type,
        ch.level + 1
    FROM 
        CompanyHierarchy ch
    JOIN 
        movie_companies mc ON mc.movie_id = ch.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ch.company_name IS NOT NULL
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    mt.title AS movie_title,
    mt.production_year,
    STRING_AGG(DISTINCT mc.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT mc.company_type, ', ') AS company_types,
    STRING_AGG(DISTINCT mcah.actor_name || ' (' || mcah.role_name || ')', ', ') AS cast,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year END) AS avg_prod_year,
    COUNT(DISTINCT mt.id) AS total_movies,
    COALESCE(MAX(CAST(NULLIF(mt.production_year, 0) AS INTEGER)), 0) AS most_recent_year
FROM 
    aka_title mt
LEFT JOIN 
    CompanyHierarchy mc ON mt.id = mc.movie_id
LEFT JOIN 
    MovieCast mcah ON mt.id = mcah.movie_id
WHERE 
    mt.production_year >= 2000
GROUP BY 
    mt.title, mt.production_year
ORDER BY 
    mt.production_year DESC;
