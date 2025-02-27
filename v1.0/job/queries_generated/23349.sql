WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY AVG(r.rating) DESC) AS rank_per_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        (SELECT 
            movie_id, 
            AVG(CASE WHEN rating IS NOT NULL THEN rating ELSE 0 END) AS rating
         FROM 
            movie_info 
         WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
         GROUP BY 
            movie_id) r ON t.id = r.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    COALESCE(mci.companies, 'Uncredited') AS companies,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Ensemble Cast' 
        WHEN tm.cast_count IS NULL THEN 'No Cast' 
        ELSE 'Small Cast' 
    END AS cast_type
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanyInfo mci ON tm.movie_id = mci.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC

### Explanation
- The query begins with a Common Table Expression (`RankedMovies`) that calculates the average movie ratings grouped by production year and ranks them based on their ratings. It also counts the number of cast members associated with each movie.
- A second CTE (`TopMovies`) filters the ranked movies to get only the top 5 movies per production year.
- Another CTE (`MovieCompanyInfo`) aggregates all companies related to each movie into a single string, using `GROUP_CONCAT` to create a comma-separated list.
- Finally, the outer query selects from the `TopMovies`, joining with `MovieCompanyInfo` to include the company names, and applies a `CASE` statement to categorize the movies based on the number of cast members.
- It filters the results for movies produced between 2000 and 2023 and orders the results by production year and cast count.
