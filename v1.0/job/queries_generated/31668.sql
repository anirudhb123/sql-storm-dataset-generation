WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.id, 
        ci.person_id, 
        ci.movie_id, 
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order = 1  -- Start with primary actors

    UNION ALL

    SELECT 
        ci.id, 
        ci.person_id, 
        ci.movie_id, 
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.nr_order > ah.depth  -- Join to find deeper roles
),
CastCount AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS actor_count
    FROM 
        ActorHierarchy
    GROUP BY 
        movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
TopMovies AS (
    SELECT 
        at.title,
        at.production_year,
        cc.actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY cc.actor_count DESC) AS ranking
    FROM 
        aka_title at
    JOIN 
        CastCount cc ON at.id = cc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mwk.keyword, 'No Keywords') AS keyword,
    tm.actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    MoviesWithKeywords mwk ON tm.movie_id = mwk.movie_id
WHERE 
    tm.ranking <= 5  -- Top 5 movies per year
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;

