WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        GROUP_CONCAT(DISTINCT ak.name) AS ActorNames,
        GROUP_CONCAT(DISTINCT cw.kind) AS CompanyTypes,
        COUNT(DISTINCT mk.keyword) AS KeywordCount
    FROM aka_title a
    JOIN cast_info ci ON a.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN movie_companies mc ON a.id = mc.movie_id
    JOIN company_type cw ON mc.company_type_id = cw.id
    JOIN movie_keyword mk ON a.id = mk.movie_id
    GROUP BY a.id
),
FilteredMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        ActorNames,
        CompanyTypes,
        KeywordCount,
        RANK() OVER (PARTITION BY ProductionYear ORDER BY KeywordCount DESC) AS RankByKeywords
    FROM RankedMovies
)
SELECT 
    MovieTitle,
    ProductionYear,
    ActorNames,
    CompanyTypes,
    KeywordCount
FROM FilteredMovies
WHERE RankByKeywords <= 3
ORDER BY ProductionYear DESC, KeywordCount DESC;
This query benchmarks string processing by aggregating and ranking movies based on their keywords while also collecting associated actors and production companies. The use of CTEs (Common Table Expressions) helps structure the query for readability and performance.
