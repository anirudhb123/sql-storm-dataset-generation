WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        MAX(mi.info) FILTER (WHERE it.info ILIKE '%Award%') AS award_info
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ms.total_actors,
        ms.total_keywords,
        COALESCE(ms.award_info, 'No Awards') AS award_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieStats ms ON rm.movie_id = ms.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_actors,
    tm.total_keywords,
    tm.award_info
FROM 
    TopMovies tm
WHERE 
    tm.total_actors > 0
ORDER BY 
    tm.production_year DESC, 
    tm.total_actors DESC
LIMIT 20;
