WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_by_year
    FROM 
        aka_title t
),
TopRankedMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        r.role AS role_name,
        CASE 
            WHEN ci.note IS NULL THEN 'No Note'
            ELSE ci.note
        END AS adjusted_note
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.nr_order IS NOT NULL OR ci.note IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        TopRankedMovies t
    LEFT JOIN 
        FilteredCast c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.movie_id, t.title, t.production_year
),
NullCheck AS (
    SELECT 
        mv.title,
        COALESCE(mv.cast_count, 0) AS total_cast,
        CASE 
            WHEN mv.actor_names IS NULL THEN 'No Actors Listed'
            ELSE mv.actor_names
        END AS actors
    FROM 
        MovieDetails mv
)
SELECT 
    n.name AS actor_name,
    cnt.movie_title,
    cnt.production_year,
    cnt.total_cast,
    cnt.actors
FROM 
    NullCheck cnt
LEFT JOIN 
    aka_name n ON n.id IN (
        SELECT DISTINCT person_id
        FROM FilteredCast fc
        WHERE fc.movie_id IN (
            SELECT movie_id 
            FROM TopRankedMovies
        )
    )
WHERE 
    cnt.total_cast > 0
ORDER BY 
    cnt.production_year DESC, cnt.total_cast DESC
LIMIT 10;
