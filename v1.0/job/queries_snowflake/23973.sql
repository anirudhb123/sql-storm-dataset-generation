
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
DetailedMovies AS (
    SELECT 
        tm.*, 
        mk.keywords_list,
        mcd.companies,
        mcd.company_types
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanyDetails mcd ON tm.movie_id = mcd.movie_id
),
FinalReport AS (
    SELECT 
        dm.movie_id,
        dm.title,
        dm.production_year,
        dm.total_cast,
        COALESCE(dm.keywords_list, 'No Keywords') AS keywords,
        COALESCE(dm.companies, 'No Companies') AS companies,
        COALESCE(dm.company_types, 'No Types') AS company_types,
        CASE 
            WHEN dm.production_year IS NULL THEN 'Unknown Year'
            WHEN dm.total_cast IS NULL THEN 'Missing Cast Info'
            ELSE 'Data Complete'
        END AS completeness_status
    FROM 
        DetailedMovies dm
)

SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    keywords,
    companies,
    company_types,
    completeness_status
FROM 
    FinalReport
ORDER BY 
    production_year DESC, total_cast DESC
LIMIT 10;
