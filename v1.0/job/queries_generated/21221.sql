WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN pi.info::numeric ELSE NULL END) AS average_rating,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

high_cast_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.average_rating
    FROM 
        ranked_movies rm
    WHERE 
        rm.ranking <= 10  -- Top 10 movies by cast count within their respective production years
),

movie_details AS (
    SELECT 
        hcm.movie_id,
        hcm.title,
        hcm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mc.company_names, 'No companies') AS companies
    FROM 
        high_cast_movies hcm
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(mk.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) mk ON hcm.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            STRING_AGG(cn.name, ', ') AS company_names
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ) mc ON hcm.movie_id = mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.average_rating,
    md.keywords,
    md.companies
FROM 
    high_cast_movies md
WHERE 
    md.average_rating IS NULL OR md.average_rating >= (
        SELECT 
            AVG(average_rating) 
        FROM 
            high_cast_movies 
        WHERE 
            average_rating IS NOT NULL
    )
ORDER BY 
    md.production_year DESC, md.total_cast DESC
FETCH FIRST 10 ROWS ONLY;

### Explanation of the Query Components
- **CTE - `ranked_movies`**: This part of the query calculates the total number of distinct cast members and the average rating for each movie, organized by production year. It also ranks the movies by those counts within their respective years.
- **CTE - `high_cast_movies`**: Filters to keep only the top 10 movies with the highest total cast counts, relative to their respective production years, utilizing the ranking computed in the previous CTE.
- **CTE - `movie_details`**: Joins high cast movies to their associated keywords and company names, aggregating them into a single string per movie.
- **Final SELECT**: Pulls data from high cast movies, applying a predicate that includes NULL logic where movies with NULL ratings still qualify if the rating is below the overall average from other movies (excluding NULLs).
- **Sorting and Fetching**: Results are ordered by production year (descending) and total cast count (descending), limiting results to the top 10 entries. 

### Unusual Constructs
- **STRING_AGG**: This function is used for concatenating keywords and company names, demonstrating how to handle multiple related records effectively.
- **COALESCE**: It is applied to manage NULL values gracefully while presenting results.
- **Subquery for Subjective Average Rating**: It computes an average rating for comparison, introducing NULL logic to allow for inclusive statistics.
- **Complex Filtering and Ordering**: Use of PARTITION BY and ROW_NUMBER to articulate nuanced ranking based on two dimensions simultaneously (production year and cast size). 

This SQL query implementation exemplifies multivariate operations, intersection logic, and real-time metrics evaluation, creating a compelling example for performance benchmarking in SQL contexts.
