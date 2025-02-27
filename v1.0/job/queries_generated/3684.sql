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
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        MAX(production_year) AS latest_movie_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
),
MovieKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
),
FinalResults AS (
    SELECT 
        a.actor_name,
        a.total_movies,
        a.latest_movie_year,
        m.keywords
    FROM 
        ActorStats a
    LEFT JOIN 
        MovieKeywords m ON a.latest_movie_year = (SELECT MAX(production_year) FROM RankedMovies r WHERE r.actor_name = a.actor_name)
)
SELECT 
    actor_name, 
    total_movies, 
    latest_movie_year, 
    COALESCE(keywords, 'No Keywords') AS keywords_info
FROM 
    FinalResults
WHERE 
    total_movies > 1
ORDER BY 
    total_movies DESC, 
    latest_movie_year DESC;
