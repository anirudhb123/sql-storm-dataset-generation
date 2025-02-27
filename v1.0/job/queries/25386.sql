WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_members
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_members,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.cast_members
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.cast_count DESC;
