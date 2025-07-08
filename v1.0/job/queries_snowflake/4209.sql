
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL 
        AND a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 10
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS total_cast,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name cn ON c.person_id = cn.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = tm.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
        AND mi.info IS NOT NULL
    )
ORDER BY 
    tm.production_year DESC, 
    total_cast DESC;
