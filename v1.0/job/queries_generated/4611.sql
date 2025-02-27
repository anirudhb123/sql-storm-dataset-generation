WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopRatedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, mk.keywords
    HAVING 
        COUNT(DISTINCT cc.person_id) > 5
),
ActorsInMovies AS (
    SELECT 
        ak.name AS actor_name, 
        COALESCE(STRING_AGG(DISTINCT m.title, ', '), 'No Movies') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    GROUP BY 
        ak.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast_count,
    ak.actor_name,
    ak.movies
FROM 
    TopRatedMovies rm
LEFT JOIN 
    ActorsInMovies ak ON rm.movie_id = ak.movie_id
WHERE 
    rm.year_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.total_cast_count DESC;
