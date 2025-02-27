
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT(a.name, ' as ', r.role) ORDER BY ci.nr_order) AS cast_list
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        TopMovies tm ON ci.movie_id = tm.movie_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mc.cast_list, 'No cast information') AS cast_list,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCast mc ON tm.movie_id = mc.movie_id
GROUP BY 
    tm.title, tm.production_year, mc.cast_list, tm.movie_id
ORDER BY 
    tm.production_year DESC, tm.title;
