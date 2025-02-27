WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mlink.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mlink ON mt.id = mlink.movie_id
    WHERE 
        mt.production_year > 2000
    
    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        mlink.linked_movie_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    INNER JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    LEFT JOIN 
        movie_link mlink ON mt.id = mlink.movie_id
),
AggregatedMovies AS (
    SELECT 
        mh.movie_id,
        STRING_AGG(DISTINCT mt.title, ', ') AS all_titles,
        COUNT(DISTINCT mt.production_year) AS unique_years_count,
        MAX(mh.depth) AS max_depth
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.id
    GROUP BY 
        mh.movie_id
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT CASE WHEN cc.company_type_id = 1 THEN cc.id END) AS count_production_companies
    FROM
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_companies cc ON mc.movie_id = cc.movie_id
    GROUP BY
        mc.movie_id, c.name, ct.kind
)
SELECT 
    am.movie_id,
    am.all_titles,
    am.unique_years_count,
    cd.company_name,
    cd.company_type,
    cd.count_production_companies,
    ROW_NUMBER() OVER (PARTITION BY am.movie_id ORDER BY cd.count_production_companies DESC NULLS LAST) AS company_rank,
    CASE 
        WHEN am.unique_years_count > 1 THEN 'Multiple Years'
        ELSE 'Single Year'
    END AS production_year_category
FROM 
    AggregatedMovies am
LEFT JOIN 
    CompanyDetails cd ON am.movie_id = cd.movie_id
WHERE 
    cd.count_production_companies > 0 
    OR (cd.company_name IS NULL AND cd.company_type IS NULL)
ORDER BY 
    am.unique_years_count DESC, 
    company_rank;
