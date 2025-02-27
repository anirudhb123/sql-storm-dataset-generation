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
ActorStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(t.production_year) AS latest_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(as.person_id, 'No actors') AS actor_id,
    COALESCE(as.movie_count, 0) AS actor_movie_count,
    COALESCE(as.latest_year, 'N/A') AS actor_latest_year,
    COALESCE(mk.keywords_list, 'No keywords') AS associated_keywords
FROM 
    RankedMovies t
LEFT JOIN 
    ActorStats as ON t.title_id = as.person_id
LEFT JOIN 
    MovieKeywords mk ON t.title_id = mk.movie_id
WHERE 
    t.year_rank <= 5
ORDER BY 
    t.production_year DESC, 
    as.movie_count DESC NULLS LAST;
