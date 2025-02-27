
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MoviesWithGenres AS (
    SELECT 
        tm.movie_id, 
        tm.movie_title, 
        tm.production_year, 
        tm.cast_count, 
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year, tm.cast_count
)
SELECT 
    mwg.movie_id,
    mwg.movie_title,
    mwg.production_year,
    mwg.cast_count,
    mwg.genres,
    cn.name AS company_name,
    ct.kind AS company_type
FROM 
    MoviesWithGenres mwg
JOIN 
    movie_companies mc ON mwg.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    mwg.production_year DESC, mwg.cast_count DESC;
