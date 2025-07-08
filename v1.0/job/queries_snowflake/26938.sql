
WITH RankedMovies AS (
    SELECT 
        mt.title AS MovieTitle,
        mt.production_year AS ProductionYear,
        COUNT(DISTINCT ci.person_id) AS CastCount,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS AkaNames,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS Keywords
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
TopMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        CastCount,
        AkaNames,
        Keywords,
        ROW_NUMBER() OVER (ORDER BY CastCount DESC) AS Rank
    FROM 
        RankedMovies
)

SELECT 
    tm.Rank,
    tm.MovieTitle,
    tm.ProductionYear,
    tm.CastCount,
    tm.AkaNames,
    tm.Keywords,
    c.kind AS CompanyType
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.MovieTitle LIMIT 1)
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    tm.Rank <= 10
ORDER BY 
    tm.Rank;
