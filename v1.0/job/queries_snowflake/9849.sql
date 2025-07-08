
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
), CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS cast_count,
        LISTAGG(ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info c 
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
), MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS genre,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS language
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.cast_count,
    cd.cast_names,
    mi.genre,
    mi.language
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, rm.title;
