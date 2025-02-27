WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),

FilteredMovies AS (
    SELECT 
        rm.actor_id,
        rm.actor_name,
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.rank <= 3
),

ActorMovieCount AS (
    SELECT 
        actor_id,
        COUNT(movie_id) AS movie_count
    FROM FilteredMovies
    GROUP BY actor_id
),

Genres AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),

FinalOutput AS (
    SELECT 
        fam.actor_id,
        fam.actor_name,
        COUNT(DISTINCT fm.movie_id) AS total_movies,
        COALESCE(g.genres, 'No Genres Available') AS genres
    FROM FilteredMovies fm
    JOIN ActorMovieCount fam ON fm.actor_id = fam.actor_id
    LEFT JOIN Genres g ON fm.movie_id = g.movie_id
    GROUP BY fam.actor_id, fam.actor_name
    HAVING COUNT(DISTINCT fm.movie_id) > 0
)

SELECT 
    fo.actor_id,
    fo.actor_name,
    fo.total_movies,
    fo.genres,
    CASE 
        WHEN fo.total_movies > 2 THEN 'Prolific Actor'
        WHEN fo.total_movies = 2 THEN 'Talented Actor'
        ELSE 'Rising Star'
    END AS actor_type
FROM FinalOutput fo
WHERE fo.genres IS NOT NULL
ORDER BY fo.total_movies DESC, fo.actor_name;
