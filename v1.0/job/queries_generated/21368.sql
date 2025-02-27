WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY a.title) AS year_rank,
        DENSE_RANK() OVER(ORDER BY a.production_year) AS overall_year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    WHERE 
        c.note IS NULL 
    GROUP BY 
        c.movie_id
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS genres
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        mg.genres
    FROM 
        RankedMovies rm
    JOIN 
        ActorCounts ac ON rm.id = ac.movie_id
    JOIN 
        MovieGenres mg ON rm.id = mg.movie_id
    WHERE 
        rm.overall_year_rank < 5  -- Filter to get only the top 5 earliest production years
),
MoviesWithNotes AS (
    SELECT 
        f.*,
        COALESCE(mi.info, 'No notes available') AS movie_note
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_info mi ON f.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
)

SELECT 
    title, 
    production_year, 
    actor_count, 
    genres,
    movie_note,
    CASE 
        WHEN actor_count > 10 THEN 'Ensemble Cast'
        WHEN actor_count <= 10 AND characters_is_null = FALSE THEN 'Small Cast'
        ELSE 'No Cast Info' 
    END AS cast_category
FROM 
    MoviesWithNotes
WHERE 
    ARRAY_LENGTH(genres, 1) IS NOT NULL 
ORDER BY 
    production_year DESC, 
    actor_count DESC
LIMIT 10;
