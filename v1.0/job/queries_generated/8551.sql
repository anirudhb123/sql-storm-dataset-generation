WITH MovieDetails AS (
    SELECT
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        a.name AS ActorName,
        ct.kind AS CastType,
        c.name AS CompanyName,
        k.keyword AS Keyword
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
        AND k.keyword IS NOT NULL
),
RankedMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        ActorName,
        CastType,
        CompanyName,
        Keyword,
        ROW_NUMBER() OVER (PARTITION BY ProductionYear ORDER BY MovieTitle) AS Rank
    FROM 
        MovieDetails
)
SELECT 
    ProductionYear,
    COUNT(*) AS TotalMovies,
    STRING_AGG(DISTINCT MovieTitle, '; ') AS MovieTitles,
    STRING_AGG(DISTINCT ActorName, '; ') AS Actors,
    STRING_AGG(DISTINCT CompanyName, '; ') AS ProductionCompanies,
    STRING_AGG(DISTINCT Keyword, '; ') AS Keywords
FROM 
    RankedMovies
GROUP BY 
    ProductionYear
ORDER BY 
    ProductionYear DESC
LIMIT 10;
