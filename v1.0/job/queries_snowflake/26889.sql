
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        LISTAGG(DISTINCT ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword) AS keywords,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.cast_names
),
TopMovies AS (
    SELECT 
        m.*,
        ROW_NUMBER() OVER (ORDER BY m.cast_count DESC) AS rank
    FROM 
        MoviesWithInfo m
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    tm.keywords,
    tm.movie_info
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
