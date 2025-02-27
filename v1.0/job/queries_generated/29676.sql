WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        c.name AS CompanyName,
        COUNT(DISTINCT k.keyword) AS KeywordCount
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),
MovieRanking AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        CompanyName,
        KeywordCount,
        ROW_NUMBER() OVER (PARTITION BY ProductionYear ORDER BY KeywordCount DESC) AS Rank
    FROM 
        RankedMovies
),
TopMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        CompanyName,
        KeywordCount
    FROM 
        MovieRanking
    WHERE 
        Rank <= 5  -- Top 5 movies per year
)
SELECT 
    TM.ProductionYear,
    STRING_AGG(TM.MovieTitle, ', ') AS TopMovies,
    STRING_AGG(TM.CompanyName, ', ') AS AssociatedCompanies,
    SUM(TM.KeywordCount) AS TotalKeywords
FROM 
    TopMovies TM
GROUP BY 
    TM.ProductionYear
ORDER BY 
    TM.ProductionYear DESC;
