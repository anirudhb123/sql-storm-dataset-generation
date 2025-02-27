WITH RankedMovies AS (
    SELECT 
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        COUNT(DISTINCT ci.person_id) AS CastCount,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS YearRank
    FROM title t
        JOIN complete_cast cc ON t.id = cc.movie_id
        JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS CompanyNames,
        MAX(ct.kind) AS CompanyType
    FROM movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords
    FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.MovieTitle,
    rm.ProductionYear,
    rm.CastCount,
    cd.CompanyNames,
    cd.CompanyType,
    mk.Keywords
FROM RankedMovies rm
LEFT JOIN CompanyDetails cd ON rm.MovieTitle = (
        SELECT t.title 
        FROM title t 
        WHERE t.id IN (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = cd.movie_id)
        LIMIT 1
    )
LEFT JOIN MovieKeywords mk ON rm.MovieTitle = (
        SELECT t.title 
        FROM title t 
        WHERE t.id = mk.movie_id
        LIMIT 1
    )
WHERE rm.YearRank <= 5 
ORDER BY rm.ProductionYear, rm.CastCount DESC;
