WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.total_cast, 0) AS total_cast,
    CASE 
        WHEN fm.total_cast IS NULL THEN 'No cast available'
        ELSE fm.cast_names
    END AS cast_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;
