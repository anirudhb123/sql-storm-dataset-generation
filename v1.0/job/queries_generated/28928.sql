WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT c.company_id) AS production_company_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        keyword_count,
        production_company_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, keyword_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        ARRAY_LENGTH(actors, 1) >= 5 AND keyword_count > 2
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actors,
    f.keyword_count,
    f.production_company_count
FROM 
    FilteredMovies f
WHERE 
    f.rank <= 10
ORDER BY 
    f.production_year DESC, f.keyword_count DESC;

### Explanation:
1. **Common Table Expressions (CTEs)**: Two CTEs are used:
   - `RankedMovies`: Gathers basic movie details along with the associated actors, the count of keywords, and the number of production companies. 
   - `FilteredMovies`: Filters the results for movies that have at least 5 actors and more than 2 keywords, and ranks them based on production year and keyword count.

2. **Aggregations**:
   - Used `ARRAY_AGG` to collect unique actor names into an array.
   - Count of distinct keywords and production companies for each movie.

3. **Filtering and Ranking**:
   - Filters down to movies fitting the criteria, sorts them, and ranks them using `ROW_NUMBER()`.

4. **Final Selection**: The final select picks the top 10 movies based on the defined criteria, returning movie ID, title, production year, actors, keyword count, and production company count.
