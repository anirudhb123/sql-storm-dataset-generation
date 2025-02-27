WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
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
)
SELECT 
    am.actor_name,
    am.title,
    am.production_year,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY am.movie_id) AS actor_count,
    CASE 
        WHEN am.production_year >= 2000 THEN 'Modern Era'
        ELSE 'Classic Era'
    END AS era
FROM 
    ActorMovies am
LEFT JOIN 
    MovieKeywords mk ON am.movie_id = mk.movie_id
JOIN 
    complete_cast cc ON cc.movie_id = am.movie_id
WHERE 
    am.rank <= 5
ORDER BY 
    am.production_year DESC, 
    am.title;
