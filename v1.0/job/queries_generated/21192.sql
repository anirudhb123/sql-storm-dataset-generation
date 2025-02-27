WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count,
        STRING_AGG(DISTINCT a.name || ' (' || rt.role || ')', ', ') OVER (PARTITION BY t.id) AS full_cast,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year IS NOT NULL
        AND (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id AND mi.info_type_id = 1) > 0
),
QualifiedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.full_cast,
        COALESCE(SUM(mi.info LIKE '%awards%') OVER (PARTITION BY rm.movie_id), 0) AS awards_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.rank <= 10
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN awards_count > 0 THEN 'Awarded'
            ELSE 'Not Awarded'
        END AS award_status
    FROM 
        QualifiedMovies
    WHERE 
        cast_count > 1
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.full_cast,
    tm.award_status
FROM 
    TopMovies tm
WHERE 
    tm.awards_count IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.title;
