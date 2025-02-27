WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        cs.company_count,
        cs.companies,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.company_count DESC) AS rank_within_year
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        company_summary cs ON mh.movie_id = cs.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.kind_id,
    COALESCE(tm.companies, 'No companies') AS companies,
    CASE 
        WHEN tm.rank_within_year IS NULL THEN 'Not Ranked'
        ELSE CAST(tm.rank_within_year AS TEXT)
    END AS rank_within_year
FROM 
    top_movies tm
WHERE 
    tm.rank_within_year <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.company_count DESC;
