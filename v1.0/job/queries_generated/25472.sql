WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ProductionYear,
        ak.name AS ActorName,
        ak.imdb_index AS ActorIndex,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS TotalCastCount,
        STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords,
        ROW_NUMBER() OVER (ORDER BY a.production_year DESC) AS Rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year, ak.name, ak.imdb_index
)

SELECT 
    rm.MovieTitle,
    rm.ProductionYear,
    rm.ActorName,
    rm.ActorIndex,
    rm.TotalCastCount,
    rm.Keywords
FROM 
    RankedMovies rm
WHERE 
    rm.Rank <= 10
ORDER BY 
    rm.ProductionYear DESC, rm.MovieTitle;
