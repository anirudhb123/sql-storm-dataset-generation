WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000
  
    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)
, CastSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
)
, CompanyAggregation AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) FILTER (WHERE cn.country_code IS NOT NULL) AS company_names,
        COUNT(DISTINCT cn.country_code) AS unique_countries
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    coalesce(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.actor_names, 'None') AS actors,
    ca.company_names,
    ca.unique_countries,
    CASE 
        WHEN mh.depth > 1 THEN 'Sequel'
        ELSE 'Original'
    END AS movie_type,
    ARRAY_AGG(DISTINCT COALESCE(ki.keyword, 'No Keywords')) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_id) AS rank_per_year
FROM MovieHierarchy mh
LEFT JOIN CastSummary cs ON mh.movie_id = cs.movie_id
LEFT JOIN CompanyAggregation ca ON mh.movie_id = ca.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cs.total_cast,
    cs.actor_names,
    ca.company_names,
    ca.unique_countries,
    mh.depth
ORDER BY mh.production_year DESC, mh.title;
