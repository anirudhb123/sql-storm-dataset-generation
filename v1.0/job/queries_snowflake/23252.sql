
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth, mh.title) AS movie_rank
    FROM 
        MovieHierarchy mh 
    WHERE 
        mh.production_year BETWEEN 2000 AND 2020
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name ELSE NULL END) AS distributor
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.depth,
    fm.movie_rank,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.companies, 'No Companies') AS companies,
    COALESCE(mc.distributor, 'No Distributor') AS distributor,
    CASE 
        WHEN mc.companies IS NULL THEN 'Company data missing'
        ELSE 'Company data available'
    END AS company_status
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON fm.movie_id = mc.movie_id
WHERE 
    (fm.production_year IS NOT NULL AND fm.movie_rank <= 5)
    OR (fm.depth > 2 AND fm.production_year IS NULL)
ORDER BY 
    fm.production_year DESC, 
    fm.depth, 
    fm.title;
