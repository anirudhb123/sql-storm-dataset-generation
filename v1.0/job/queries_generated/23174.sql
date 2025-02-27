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

CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_size
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS director,
        MAX(CASE WHEN i.info_type_id = 2 THEN i.info END) AS genre
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx i ON m.movie_id = i.movie_id
    GROUP BY 
        m.movie_id
),

FilteredMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        cc.cast_size,
        mi.director,
        mi.genre
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastCounts cc ON r.movie_id = cc.movie_id
    LEFT JOIN 
        MovieInfo mi ON r.movie_id = mi.movie_id
    WHERE 
        cc.cast_size IS NOT NULL 
        AND r.year_rank <= 5
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(f.cast_size, 0) AS cast_size,
    COALESCE(f.director, 'Unknown Director') AS director,
    COALESCE(f.genre, 'Genre Not Specified') AS genre,
    COUNT(mk.keyword) AS keyword_count
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
GROUP BY 
    f.movie_id, f.title, f.production_year, f.cast_size, f.director, f.genre
HAVING 
    COUNT(mk.keyword) > 0 OR 
    (f.cast_size < 3 AND f.production_year < 2000)
ORDER BY 
    f.production_year DESC, 
    f.cast_size DESC;
