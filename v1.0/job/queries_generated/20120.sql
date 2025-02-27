WITH RankedMovies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_per_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movies_count
    FROM 
        title t
    WHERE
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.title_id, 
        rm.title, 
        rm.production_year, 
        rm.rank_per_year,
        COALESCE(am.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'No Keywords') AS keywords_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.title_id = am.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
)
SELECT 
    m.title_id, 
    m.title, 
    m.production_year,
    m.rank_per_year,
    m.total_actors,
    m.keywords_info,
    CASE 
        WHEN m.total_actors = 0 THEN 'No Actors Available'
        WHEN m.keywords_info = 'No Keywords' THEN 'No Keywords Available'
        ELSE 'Complete Data'
    END AS data_availability,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_label,
    COUNT(DISTINCT CASE WHEN m.total_actors > 5 THEN m.title_id END) OVER () AS popular_movies_count
FROM 
    MoviesWithDetails m
WHERE 
    m.rank_per_year = 1 -- Get only latest movie per year
ORDER BY 
    m.production_year DESC, 
    m.total_actors DESC;

This SQL query retrieves a list of movies from the `title` table, ranks them by production year, and aggregates information on the actors and keywords associated with each movie. It incorporates CTEs (Common Table Expressions) to establish intermediate datasets for movies' rankings, actor counts, and keywords. It uses window functions for counting rows and provides several filtering conditions, covering many SQL constructs, such as conditional expressions for categorization and aggregation functions for string concatenation. Furthermore, it incorporates logic to handle NULL values and other edge cases, such as movies with no actors or keywords.
