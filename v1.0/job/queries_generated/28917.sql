WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS num_actors,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_actors,
        actor_names
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
        AND num_actors > 5
),
KeywordedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.num_actors,
        fm.actor_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    JOIN 
        keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, fm.num_actors, fm.actor_names
)
SELECT 
    kf.movie_id,
    kf.title,
    kf.production_year,
    kf.num_actors,
    kf.actor_names,
    kf.keywords,
    COALESCE(mc.note, 'No Notes') AS company_note
FROM 
    KeywordedMovies kf
LEFT JOIN 
    movie_companies mc ON kf.movie_id = mc.movie_id
ORDER BY 
    kf.production_year DESC, 
    kf.num_actors DESC;
