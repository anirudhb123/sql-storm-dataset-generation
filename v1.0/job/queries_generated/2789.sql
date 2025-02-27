WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) as rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
MovieGenres AS (
    SELECT 
        m.title,
        k.keyword AS genre
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(mg.genre, ', ') AS genres
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.title = mg.title
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.title, rm.production_year, rm.actor_count
)
SELECT 
    t.title,
    t.production_year,
    t.actor_count,
    COALESCE(t.genres, 'No Genre') AS genres
FROM 
    TopMovies t
ORDER BY 
    t.production_year DESC, 
    t.actor_count DESC;
