WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(c.person_id) > 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name END) AS distributor
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.id
),
FinalResults AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(pm.cast_count, 0) AS cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mci.companies, 'No Companies') AS companies,
        COALESCE(mci.distributor, 'N/A') AS distributor
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        PopularMovies pm ON mh.movie_id = pm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    keywords,
    companies,
    distributor,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
FROM 
    FinalResults
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, cast_count DESC;
