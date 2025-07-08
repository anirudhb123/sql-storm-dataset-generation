
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
CastStats AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.total_cast,
        cs.cast_names,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CastStats AS cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        movie_info AS mi ON rm.movie_id = mi.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COUNT(*) OVER () AS total_movies,
    CASE 
        WHEN md.total_cast IS NULL THEN 'No Cast'
        WHEN md.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    MovieDetails AS md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM RankedMovies)
GROUP BY 
    md.title, md.production_year, md.total_cast, md.cast_names
ORDER BY 
    md.title;
