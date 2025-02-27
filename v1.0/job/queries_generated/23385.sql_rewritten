WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
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
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ac.actor_count, 0) AS actor_count,
    CASE 
        WHEN ac.actor_count > 10 THEN 'Many Actors'
        WHEN ac.actor_count BETWEEN 6 AND 10 THEN 'Moderate Actors'
        ELSE 'Few Actors'
    END AS actor_count_category
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieKeywords mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    ActorCounts ac ON f.movie_id = ac.movie_id
WHERE 
    f.production_year IS NOT NULL
    AND (f.production_year < 1990 OR f.production_year > 2010)
ORDER BY 
    f.production_year DESC, ac.actor_count DESC;