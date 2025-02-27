WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopGenres AS (
    SELECT 
        k.keyword,
        COUNT(m.movie_id) AS movie_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        k.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    tg.keyword AS top_genre
FROM 
    RankedMovies rm
LEFT JOIN 
    TopGenres tg ON rm.movie_id IN (
        SELECT mk.movie_id
        FROM movie_keyword mk
        WHERE mk.movie_id = rm.movie_id
    )
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
