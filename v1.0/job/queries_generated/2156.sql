WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(c.movie_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
),
TopRankedMovies AS (
    SELECT 
        title, 
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieGenres AS (
    SELECT 
        a.id AS movie_id,
        STRING_AGG(g.kind, ', ') AS genres
    FROM 
        aka_title AS a
    LEFT JOIN 
        movie_info AS mi ON a.id = mi.movie_id
    LEFT JOIN 
        kind_type AS g ON mi.info_type_id = g.id
    GROUP BY 
        a.id
)
SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    COALESCE(g.genres, 'No Genre') AS genres,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era
FROM 
    TopRankedMovies AS t
LEFT JOIN 
    MovieGenres AS g ON t.title = g.movie_id
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
