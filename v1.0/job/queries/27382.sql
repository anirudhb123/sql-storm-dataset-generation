WITH MovieRankings AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        COUNT(c.person_id) AS CastCount,
        ARRAY_AGG(DISTINCT ak.name) AS ActorNames,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS Genre,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS Description
    FROM 
        aka_title AS a
    JOIN 
        complete_cast AS cc ON a.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    JOIN 
        movie_info AS mi ON a.id = mi.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.id, a.title, a.production_year
),
RankedMovies AS (
    SELECT 
        MovieTitle,
        ProductionYear,
        CastCount,
        ActorNames,
        Genre,
        Description,
        RANK() OVER (ORDER BY CastCount DESC) AS Rank
    FROM 
        MovieRankings
)
SELECT 
    Rank,
    MovieTitle,
    ProductionYear,
    CastCount,
    ActorNames,
    Genre,
    Description
FROM 
    RankedMovies
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
