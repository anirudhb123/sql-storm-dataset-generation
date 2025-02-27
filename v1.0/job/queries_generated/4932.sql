WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COALESCE(k.keyword, 'No Keyword') AS movie_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mc.total_cast,
        mc.actor_names
    FROM 
        RankedMovies rm
    JOIN 
        MovieCast mc ON rm.title = mc.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    CASE 
        WHEN fm.total_cast > 3 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_type,
    fm.actor_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title;
