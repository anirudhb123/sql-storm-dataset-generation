WITH RankedMovies AS (
    SELECT 
        a.name AS Actor,
        t.title AS MovieTitle,
        t.production_year AS ProductionYear,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS MovieRank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        Actor,
        MovieTitle,
        ProductionYear
    FROM 
        RankedMovies
    WHERE 
        MovieRank <= 5
)
SELECT 
    fm.Actor,
    string_agg(fm.MovieTitle, ', ') AS MovieTitles, 
    MIN(fm.ProductionYear) AS EarliestYear,
    MAX(fm.ProductionYear) AS LatestYear,
    COUNT(DISTINCT fm.MovieTitle) AS UniqueMovies,
    CASE 
        WHEN COUNT(DISTINCT fm.MovieTitle) > 2 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS ActorType
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON (mi.movie_id IN (SELECT DISTINCT movie_id FROM aka_title WHERE title LIKE '%' || fm.MovieTitle || '%'))
WHERE 
    mi.info IS NOT NULL OR mi.note IS NULL
GROUP BY 
    fm.Actor
HAVING 
    MAX(fm.ProductionYear) > (
        SELECT AVG(ProductionYear)
        FROM RankedMovies
        WHERE MovieTitle IS NOT NULL
    )
ORDER BY 
    UniqueMovies DESC, LatestYear DESC;

This SQL query achieves the following:

- It uses Common Table Expressions (CTEs) to first rank movies for each actor and then filter those for specific criteria.
- It performs multiple joins, including a LEFT JOIN with the `movie_info` table to analyze movie-related information.
- It incorporates string aggregation and calculates the minimum and maximum production years.
- It utilizes a window function (`ROW_NUMBER`) to rank the movies by production year for each actor and determine their prolific status.
- The `HAVING` clause and subquery check ensures that only actors with a maximum production year greater than the average of all movies are included.
- Finally, the result is ordered based on the number of unique movies and the latest production year.
