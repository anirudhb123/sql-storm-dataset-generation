
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
MovieStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MIN(p.info) AS earliest_info,
        MAX(p.info) AS latest_info
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        ms.total_cast,
        ms.earliest_info,
        ms.latest_info,
        COALESCE(NULLIF(ms.earliest_info, ''), 'No Info') AS adjusted_earliest_info
    FROM 
        RankedMovies rm
    JOIN 
        MovieStatistics ms ON rm.movie_id = ms.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    rm.production_year,
    tm.total_cast,
    tm.earliest_info,
    tm.latest_info,
    tm.adjusted_earliest_info
FROM 
    TopMovies tm
JOIN 
    RankedMovies rm ON tm.movie_id = rm.movie_id
ORDER BY 
    rm.production_year DESC, 
    tm.total_cast DESC;
