
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fc.total_cast,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast fc ON rm.movie_id = fc.movie_id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.movie_info,
    COALESCE(ARRAY_AGG(DISTINCT ka.name) ORDER BY ka.name::STRING, 'No Cast') AS cast_names,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_cast, md.movie_info
ORDER BY 
    md.production_year DESC, md.title ASC;
