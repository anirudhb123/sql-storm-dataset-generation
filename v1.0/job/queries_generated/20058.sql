WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.total_cast,
        COALESCE(mc.company_count, 0) AS company_count,
        mk.keywords
    FROM 
        RankedMovies r
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mc ON mc.movie_id = r.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = r.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.total_cast,
    mwc.company_count,
    mwc.keywords,
    CASE 
        WHEN mwc.total_cast > 10 THEN 'Ensemble Cast'
        WHEN mwc.total_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Minimal Cast'
    END AS cast_size_category
FROM 
    MoviesWithCompanies mwc
WHERE 
    mwc.rank_by_cast = 1 -- Only top movie per year
    AND mwc.production_year IS NOT NULL
    AND mwc.company_count > 0
ORDER BY 
    mwc.production_year DESC, 
    mwc.total_cast DESC
LIMIT 10;

-- Additional analytical part to explore the relationship between cast size and number of keywords
SELECT 
    mwc.production_year,
    avg(mwc.total_cast) AS avg_cast,
    AVG(COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mwc.movie_id), 0)) AS avg_keywords
FROM 
    MoviesWithCompanies mwc
GROUP BY 
    mwc.production_year
HAVING 
    COUNT(mwc.movie_id) > 5
ORDER BY 
    mwc.production_year DESC;

### Explanation of the Query:
1. **CTEs**: 
    - `RankedMovies`: Computes a rank of movies based on the number of unique cast members per production year.
    - `MovieKeywords`: Aggregates keywords for each movie.
    - `MoviesWithCompanies`: Joins the previously defined CTEs, calculating the total number of cast and companies per movie.

2. **Main SELECT**: 
    - Fetches relevant movie details, including the cast size category based on total cast numbers.
    - It's constrained to only consider top-ranked movies from each production year with at least one associated company.

3. **Analytical Part**: 
    - An additional aggregation is performed to explore the average cast size against the average number of keywords for each production year, filtering for years that have more than five movies.

4. **NULL Logic**: 
    - Uses `COALESCE` to handle NULLs in the company count and keyword counts.

5. **String Aggregation**: 
    - Unites keywords into a single string for easy visualization.

This design combines various SQL constructs, including window functions, CTEs, conditional logic, and aggregate functions, showcasing a complex SQL problem-solving approach.
