WITH Recursive ActorRoles AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name an ON an.person_id = ca.person_id
    WHERE 
        an.name LIKE '%Smith%'
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(DISTINCT ca.movie_id) > 1
),
CriticalMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mk.keyword AS main_keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS keyword_rank
    FROM 
        aka_title mt
    LEFT OUTER JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000
        AND mk.keyword IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        cm.movie_id,
        cm.title,
        cm.production_year,
        cm.main_keyword
    FROM 
        CriticalMovies cm
    WHERE 
        cm.keyword_rank <= 3
)
SELECT 
    ar.person_id,
    COUNT(DISTINCT fm.movie_id) AS significant_movie_count,
    STRING_AGG(DISTINCT fm.title, ', ') AS movies,
    SUM(COALESCE(ci.nr_order, 0)) AS total_order
FROM 
    ActorRoles ar
LEFT JOIN 
    cast_info ci ON ar.person_id = ci.person_id
LEFT JOIN 
    FilteredMovies fm ON ci.movie_id = fm.movie_id
GROUP BY 
    ar.person_id
HAVING 
    COUNT(DISTINCT fm.movie_id) > 0
ORDER BY 
    significant_movie_count DESC,
    total_order ASC
LIMIT 10;

WITH AdditionalInfo AS (
  SELECT 
    DISTINCT cn.name AS company_name,
    ct.kind AS company_type,
    COUNT(mc.id) AS movie_count
  FROM 
    company_name cn
  INNER JOIN 
    movie_companies mc ON cn.id = mc.company_id
  INNER JOIN 
    company_type ct ON mc.company_type_id = ct.id
  WHERE 
    cn.country_code IS NOT NULL
  GROUP BY 
    cn.name, ct.kind
)
SELECT 
    ci.info AS additional_info,
    ai.company_name,
    ai.company_type,
    ai.movie_count
FROM 
    person_info ci
FULL OUTER JOIN 
    AdditionalInfo ai ON ci.person_id = ai.movie_count
WHERE 
    ci.info_type_id IS NOT NULL OR ai.company_count IS NOT NULL
ORDER BY 
    CASE 
        WHEN ci.info IS NULL AND ai.movie_count IS NULL THEN 1
        WHEN ci.info IS NOT NULL AND ai.movie_count IS NULL THEN 2
        WHEN ci.info IS NULL AND ai.movie_count IS NOT NULL THEN 3
        ELSE 4
    END,
    ai.movie_count DESC NULLS LAST;
