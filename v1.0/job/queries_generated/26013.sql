WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
HighActorCountMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        actor_count > 10 -- select movies with more than 10 actors
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
FinalResults AS (
    SELECT 
        ma.title,
        ma.production_year,
        ma.actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        HighActorCountMovies ma
    LEFT JOIN 
        MoviesWithKeywords mw ON ma.movie_id = mw.movie_id
    GROUP BY 
        ma.movie_id, ma.title, ma.production_year, ma.actor_count
)
SELECT 
    title,
    production_year,
    actor_count,
    keywords
FROM 
    FinalResults
ORDER BY 
    actor_count DESC, production_year ASC;
