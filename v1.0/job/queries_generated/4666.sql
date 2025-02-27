WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
    HAVING 
        COUNT(*) > 2
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
MoviesWithActorInfo AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        ac.total_movies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_title = mk.movie_title
    JOIN 
        ActorCount ac ON rm.actor_name = ac.actor_name
)
SELECT 
    mwa.actor_name,
    mwa.movie_title,
    mwa.production_year,
    mwa.keywords,
    mwa.total_movies
FROM 
    MoviesWithActorInfo mwa
WHERE 
    mwa.total_movies > 3 AND
    (mwa.keywords LIKE '%action%' OR mwa.keywords LIKE '%drama%')
ORDER BY 
    mwa.production_year DESC, mwa.actor_name ASC;
