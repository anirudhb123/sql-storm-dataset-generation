
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
DetailedMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COALESCE(mi.info, 'No details available') AS movie_detail
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, mi.info
)
SELECT 
    dmi.movie_id,
    dmi.title,
    dmi.production_year,
    dmi.actors,
    dmi.companies,
    dmi.movie_detail
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year > 2000
ORDER BY 
    dmi.production_year DESC, dmi.title ASC;
