WITH RECURSIVE MoviePaths AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth,
        mt.production_year,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        mp.depth + 1,
        at.production_year,
        path || at.title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MoviePaths mp ON ml.movie_id = mp.movie_id
    WHERE 
        mp.depth < 3
),
TopMovies AS (
    SELECT 
        mp.movie_id,
        mp.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT mc.note) AS company_notes
    FROM 
        MoviePaths mp
    LEFT JOIN 
        movie_companies mc ON mp.movie_id = mc.movie_id
    GROUP BY 
        mp.movie_id, mp.title
    HAVING 
        COUNT(DISTINCT mc.company_id) >= 2
),
DetailedMovieStats AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.company_count,
        tm.company_notes,
        COUNT(DISTINCT ci.id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast,
        AVG(NULLIF(mt.production_year, 0)) AS avg_production_year
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_title mt ON tm.movie_id = mt.id
    GROUP BY 
        tm.movie_id, tm.title, tm.company_count, tm.company_notes
)
SELECT 
    dms.title,
    dms.company_count,
    dms.cast_count,
    dms.noted_cast,
    dms.avg_production_year,
    RANK() OVER (ORDER BY dms.cast_count DESC) AS cast_rank,
    CASE
        WHEN dms.avg_production_year IS NOT NULL THEN 
            CASE 
                WHEN dms.avg_production_year < 2005 THEN 'Early 2000s'
                WHEN dms.avg_production_year < 2010 THEN 'Mid 2000s'
                ELSE 'Late 2000s'
            END
        ELSE 'Unknown'
    END AS production_period
FROM 
    DetailedMovieStats dms
WHERE 
    dms.cast_count > 5
ORDER BY 
    dms.company_count DESC, dms.cast_count DESC;
