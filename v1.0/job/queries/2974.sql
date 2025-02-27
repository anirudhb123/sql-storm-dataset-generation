WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as rn,
        COUNT(*) OVER (PARTITION BY a.production_year) as movie_count,
        STRING_AGG(DISTINCT b.name, ', ') AS actors
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name b ON c.person_id = b.person_id
    GROUP BY a.id, a.title, a.production_year
),
YearlyMovieCount AS (
    SELECT 
        production_year,
        AVG(movie_count) AS avg_movies_per_year
    FROM RankedMovies
    GROUP BY production_year
),
NotableMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actors,
        ym.avg_movies_per_year
    FROM RankedMovies rm
    JOIN YearlyMovieCount ym ON rm.production_year = ym.production_year
    WHERE rm.rn = 1 AND rm.movie_count > ym.avg_movies_per_year
)
SELECT 
    nm.title, 
    nm.production_year,
    COALESCE(nm.actors, 'No actors listed') AS actors,
    CONCAT('Year ', nm.production_year, ': A notable film with ', COUNT(c.movie_id), ' actors.') AS description
FROM NotableMovies nm
LEFT JOIN cast_info c ON nm.movie_id = c.movie_id
GROUP BY nm.title, nm.production_year, nm.actors
HAVING COUNT(c.movie_id) >= 1
ORDER BY nm.production_year DESC;
