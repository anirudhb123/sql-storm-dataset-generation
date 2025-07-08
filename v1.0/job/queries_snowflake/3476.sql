
WITH RankedMovies AS (
    SELECT 
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS RankInYear
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsInMovies AS (
    SELECT 
        ak.name AS ActorName,
        t.title AS MovieTitle,
        ci.nr_order AS RoleOrder
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS CompanyCount,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS Companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.MovieTitle,
    r.ProductionYear,
    COALESCE(a.ActorName, 'No Actor') AS ActorName,
    COALESCE(a.RoleOrder, 0) AS RoleOrder,
    COALESCE(m.CompanyCount, 0) AS CompanyCount,
    COALESCE(m.Companies, 'No Companies') AS Companies
FROM 
    RankedMovies r
LEFT JOIN 
    ActorsInMovies a ON r.MovieTitle = a.MovieTitle
LEFT JOIN 
    MovieCompanies m ON r.MovieTitle = (SELECT title FROM aka_title WHERE id = m.movie_id)
WHERE 
    r.RankInYear <= 5
ORDER BY 
    r.ProductionYear DESC, 
    r.MovieTitle, 
    a.RoleOrder;
