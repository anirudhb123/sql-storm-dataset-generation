WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        TopMovies tm ON ci.movie_id = (
            SELECT 
                tm2.id 
            FROM 
                aka_title tm2 
            WHERE 
                tm2.title = tm.title AND 
                tm2.production_year = tm.production_year 
            LIMIT 1
        )
    GROUP BY 
        ci.person_id
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
FinalResults AS (
    SELECT 
        a.id AS actor_id, 
        n.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_starred,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    LEFT JOIN 
        MovieKeywords mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        (SELECT DISTINCT movie_id FROM TopMovies) tm ON ci.movie_id = tm.movie_id
    GROUP BY 
        a.id, n.name, mk.keywords
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 0
)
SELECT 
    fr.actor_id,
    fr.actor_name,
    fr.movies_starred,
    fr.keywords
FROM 
    FinalResults fr
WHERE 
    fr.movies_starred > (SELECT AVG(movie_count) FROM ActorMovieCounts)
ORDER BY 
    fr.movies_starred DESC;
