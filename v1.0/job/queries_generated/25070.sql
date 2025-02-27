WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        k.keyword AS GenreKeyword,
        COUNT(c.id) AS CastCount,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.id) DESC) AS Rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

AggregatedActors AS (
    SELECT 
        n.name AS ActorName,
        COUNT(c.movie_id) AS MovieCount
    FROM 
        name n
    JOIN 
        cast_info c ON n.id = c.person_id
    GROUP BY 
        n.name
)

SELECT 
    rm.MovieTitle,
    rm.ProductionYear,
    ARRAY_AGG(DISTINCT ak.ActorName) AS NotableActors,
    rm.GenreKeyword,
    rm.CastCount,
    a.MovieCount AS ActorMovieCount
FROM 
    RankedMovies rm
JOIN 
    AggregatedActors a ON rm.CastCount = a.MovieCount
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = rm.MovieId)
WHERE 
    rm.Rank <= 5
GROUP BY 
    rm.MovieTitle, rm.ProductionYear, rm.GenreKeyword, rm.CastCount, a.MovieCount
ORDER BY 
    rm.CastCount DESC, rm.ProductionYear ASC;
