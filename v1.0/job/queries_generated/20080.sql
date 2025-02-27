WITH RankedCast AS (
    SELECT 
        ci.movie_id,
        cn.name AS character_name,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        char_name cn ON cn.imdb_id = ak.person_id
),
RecentMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title) 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FilteredCast AS (
    SELECT 
        rc.movie_id,
        rc.actor_name,
        rc.character_name,
        rc.role_rank
    FROM 
        RankedCast rc
    WHERE 
        rc.role_rank <= 3
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(fc.actor_name, 'Unknown') AS main_actor,
    COALESCE(fc.character_name, 'Unknown Character') AS character_played,
    COALESCE(kc.keyword_total, 0) AS total_keywords,
    rm.company_count
FROM 
    RecentMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    KeywordCount kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.company_count > 0
ORDER BY 
    rm.production_year DESC,
    rm.title;

### Explanation of Constructs:
1. **Common Table Expressions (CTEs):** Multiple CTEs are utilized to break down the query into more manageable parts:
   - `RankedCast`: Ranks cast members by the order they appear in a movie.
   - `RecentMovies`: Filtered to include only movies from the last 10 years, counting associated companies.
   - `KeywordCount`: Counts the number of keywords associated with each movie.
   - `FilteredCast`: Limits the results to the top three roles for each movie.

2. **Outer Joins:** The query uses a series of LEFT JOINs to include movies with or without corresponding cast members and keywords.

3. **Window Functions:** The `ROW_NUMBER()` function is used in `RankedCast` to rank cast roles within each movie.

4. **Complicated Predicates:** The WHERE clause filters the RecentMovies to ensure only those with at least one associated production company are included.

5. **COALESCE Function:** This is used to handle NULL logic to provide default values when no data is available.

6. **Ordering Results:** The final SELECT statement orders results first by production year and then by title, allowing for a clear, organized output.

This query showcases the complexity and capability of SQL to retrieve comprehensive data in an organized manner from the provided schema while leveraging advanced SQL features.
