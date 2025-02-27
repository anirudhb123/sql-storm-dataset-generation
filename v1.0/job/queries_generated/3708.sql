WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (
            SELECT 
                id 
            FROM 
                kind_type 
            WHERE 
                kind = 'movie'
        )
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS total_cast
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        cm.company_name,
        cm.company_type,
        cc.total_cast,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY cc.total_cast DESC NULLS LAST) AS cast_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN 
        CompleteCast cc ON rm.movie_id = cc.movie_id
)
SELECT 
    title,
    production_year,
    company_name,
    company_type,
    total_cast,
    cast_rank
FROM 
    FinalResults
WHERE 
    total_cast > 2
ORDER BY 
    production_year DESC, cast_rank;
