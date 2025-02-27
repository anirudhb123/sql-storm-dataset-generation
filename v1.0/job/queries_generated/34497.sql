WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
  
    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM aka_title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    GROUP BY m.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ci.company_names, 'No companies listed') AS companies,
    rm.cast_count,
    mh.level AS hierarchy_level
FROM RankedMovies rm
LEFT JOIN CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN MovieHierarchy mh ON rm.movie_id = mh.movie_id
WHERE rm.rn <= 10  -- Limit to top 10 movies per year by cast count
  AND rm.production_year >= 2000
ORDER BY rm.production_year DESC, rm.cast_count DESC;
