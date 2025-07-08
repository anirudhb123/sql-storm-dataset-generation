
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(mi.info, 'No Rating') AS rating_info
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_info mi ON r.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        r.year_rank <= 5
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name cn ON c.person_id = cn.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.rating_info,
    COALESCE(mc.cast_count, 0) AS cast_count,
    COALESCE(mc.cast_names, 'No Cast') AS cast_names
FROM 
    TopRatedMovies t
LEFT JOIN 
    MovieCast mc ON t.movie_id = mc.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
