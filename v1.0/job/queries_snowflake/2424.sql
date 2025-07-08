
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        mk.movie_id,
        LISTAGG(kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mk.movie_id
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(d.director_count, 0) AS director_count,
    COALESCE(mg.genres, 'No Genres') AS genres
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorInfo d ON rm.movie_id = d.movie_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    rm.rank_year = 1 
    AND (d.director_count IS NULL OR d.director_count = 0 OR d.director_count > 1)
ORDER BY 
    rm.production_year DESC, rm.title;
