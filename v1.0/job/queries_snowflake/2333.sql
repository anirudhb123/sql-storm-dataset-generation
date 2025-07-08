
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = 1 AND 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS movie_note
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(mi.movie_note, 'No Information') AS movie_award_info
FROM 
    RankedMovies m
LEFT JOIN 
    CastDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON m.movie_id = mi.movie_id
WHERE 
    m.year_rank <= 5
ORDER BY 
    m.production_year DESC;
