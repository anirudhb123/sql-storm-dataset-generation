WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT m.movie_id) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
TopActors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 3
),
MoviesWithCharacterNames AS (
    SELECT 
        m.id AS movie_id,
        cn.name AS character_name
    FROM 
        complete_cast cc
    JOIN 
        char_name cn ON cc.subject_id = cn.id
    JOIN 
        aka_title m ON cc.movie_id = m.movie_id
)
SELECT 
    ra.title,
    ra.production_year,
    ta.movie_count,
    mcn.character_name
FROM 
    RankedMovies ra
LEFT JOIN 
    TopActors ta ON ra.title_rank = ta.movie_count
LEFT JOIN 
    MoviesWithCharacterNames mcn ON ra.title = mcn.movie_id
WHERE 
    ra.total_movies > 10 
    AND (mcn.character_name IS NOT NULL OR ra.production_year IS NULL)
ORDER BY 
    ra.production_year DESC,
    ra.title ASC;
