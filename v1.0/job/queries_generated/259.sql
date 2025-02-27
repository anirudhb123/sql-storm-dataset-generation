WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        AVG(COALESCE(mk.movie_id, 0)) AS average_keyword_usage,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 'Has Note' ELSE 'No Note' END) AS note_status
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        ms.*,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.actor_count DESC) AS year_rank
    FROM 
        MovieStats ms
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.keyword_count,
        rm.average_keyword_usage,
        rm.note_status
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 5 AND 
        rm.keyword_count > 2 AND
        rm.note_status = 'Has Note'
)
SELECT 
    DISTINCT fm.title,
    fm.production_year,
    fm.actor_count,
    fm.keyword_count,
    'Year ' || fm.production_year || ' Movie Analysis' AS analysis
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.actor_count DESC;
