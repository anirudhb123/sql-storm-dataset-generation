
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT cc.id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

GenreStats AS (
    SELECT
        k.kind AS genre,
        COUNT(DISTINCT m.id) AS movie_count,
        AVG(m.production_year) AS average_year
    FROM 
        aka_title m
    JOIN 
        kind_type k ON m.kind_id = k.id
    GROUP BY 
        k.kind
),

AvgCastRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_participated,
        AVG(ri.role_count) AS avg_roles
    FROM 
        cast_info ci
    JOIN 
        (SELECT 
            person_id, COUNT(DISTINCT role_id) AS role_count
         FROM 
            cast_info
         GROUP BY 
            person_id) ri ON ci.person_id = ri.person_id
    GROUP BY 
        ci.person_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_count,
    gs.genre,
    gs.movie_count,
    gs.average_year,
    acr.movies_participated,
    acr.avg_roles
FROM 
    RankedMovies rm
JOIN 
    GenreStats gs ON rm.production_year = gs.average_year
JOIN 
    AvgCastRoles acr ON acr.movies_participated > 5
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
