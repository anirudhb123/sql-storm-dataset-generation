WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_title ak ON t.id = ak.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
MovieAverages AS (
    SELECT 
        AVG(total_cast) AS avg_cast,
        MAX(production_year) AS latest_year
    FROM RankedMovies
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.aka_names,
        rm.keywords,
        ma.avg_cast,
        ma.latest_year
    FROM RankedMovies rm
    CROSS JOIN MovieAverages ma
    WHERE rm.total_cast > ma.avg_cast
      AND rm.production_year = ma.latest_year
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.aka_names,
    fm.keywords
FROM FilteredMovies fm
ORDER BY fm.total_cast DESC;
