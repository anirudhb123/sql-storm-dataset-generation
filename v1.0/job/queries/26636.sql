WITH MovieDetails AS (
    SELECT 
        mt.title AS MovieTitle,
        mt.production_year AS ProductionYear,
        ak.name AS ActorName,
        ct.kind AS CompanyType,
        mi.info AS MovieInfo
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    JOIN 
        movie_info mi ON mi.movie_id = mt.id
    WHERE 
        mt.production_year > 2000
        AND ak.name IS NOT NULL
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
),
AggregatedResults AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        COUNT(DISTINCT ActorName) AS NumberOfActors,
        STRING_AGG(DISTINCT ActorName, ', ') AS ActorsList,
        STRING_AGG(DISTINCT CompanyType, ', ') AS CompaniesInvolved
    FROM 
        MovieDetails
    GROUP BY 
        MovieTitle, ProductionYear
)
SELECT 
    MovieTitle,
    ProductionYear,
    NumberOfActors,
    ActorsList,
    CompaniesInvolved
FROM 
    AggregatedResults
ORDER BY 
    ProductionYear DESC, NumberOfActors DESC;

