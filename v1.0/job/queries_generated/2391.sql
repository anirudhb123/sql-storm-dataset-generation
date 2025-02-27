WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS YearRank
    FROM
        aka_title a
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'duration')
),
TopMovies AS (
    SELECT 
        rm.MovieTitle,
        rm.ProductionYear,
        CAST(SUBSTRING(mi.info FROM '^\d+') AS INTEGER) AS Duration
    FROM 
        RankedMovies rm
    JOIN 
        movie_info mi ON rm.MovieTitle = mi.info
    WHERE 
        rm.YearRank <= 10
),
MoviesWithKeywords AS (
    SELECT 
        tm.MovieTitle,
        tm.ProductionYear,
        STRING_AGG(k.keyword, ', ') AS Keywords
    FROM 
        TopMovies tm
    JOIN 
        movie_keyword mk ON tm.MovieTitle = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.MovieTitle, tm.ProductionYear
),
FinalResults AS (
    SELECT 
        mwk.MovieTitle,
        mwk.ProductionYear,
        COALESCE(wc.kind, 'Unknown') AS CompanyType,
        mwk.Keywords,
        ROW_NUMBER() OVER (ORDER BY mwk.ProductionYear DESC) AS MovieRank
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        movie_companies mc ON mwk.MovieTitle = mc.movie_id
    LEFT JOIN 
        company_type wc ON mc.company_type_id = wc.id
)
SELECT 
    f.MovieTitle,
    f.ProductionYear,
    f.CompanyType,
    f.Keywords,
    f.MovieRank
FROM 
    FinalResults f
WHERE 
    f.MovieRank <= 10
ORDER BY 
    f.ProductionYear DESC, f.MovieRank;
