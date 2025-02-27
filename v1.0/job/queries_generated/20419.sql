WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY mc.movie_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        complete_cast cc
    LEFT JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        cc.movie_id
),
MoviesWithNulls AS (
    SELECT 
        rm.movie_id,
        rm.title,
        mci.company_name,
        mci.company_type,
        cci.total_cast,
        cci.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        CompleteCastInfo cci ON rm.movie_id = cci.movie_id
    WHERE 
        mci.company_name IS NOT NULL OR cci.total_cast IS NULL
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.company_name,
    mw.company_type,
    COALESCE(mw.total_cast, 0) AS total_cast,
    mw.actor_names,
    CASE 
        WHEN mw.total_cast > 20 THEN 'Large Cast'
        WHEN mw.total_cast BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    RANK() OVER (ORDER BY mw.total_cast DESC) AS cast_rank
FROM 
    MoviesWithNulls mw
WHERE 
    mw.company_type LIKE '%Production%'
    AND mw.title NOT LIKE '%untitled%'
ORDER BY 
    mw.production_year DESC NULLS LAST,
    mw.title ASC;
