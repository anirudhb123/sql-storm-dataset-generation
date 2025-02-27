WITH RankedTitles AS (
    SELECT 
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieTitles AS (
    SELECT 
        mt.movie_id,
        mt.title,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        mt.movie_id, mt.title
),
DetailedActors AS (
    SELECT 
        ak.name AS actor_name,
        pt.movie_id,
        ROW_NUMBER() OVER (PARTITION BY pt.movie_id ORDER BY ak.name) AS actor_rank,
        COUNT(*) OVER (PARTITION BY pt.movie_id) AS total_cast
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title pt ON ci.movie_id = pt.id
)
SELECT 
    mt.title,
    mt.production_year,
    mt.company_names,
    mt.keyword_count,
    da.actor_name,
    da.actor_rank,
    da.total_cast
FROM 
    MovieTitles mt
LEFT JOIN 
    DetailedActors da ON mt.movie_id = da.movie_id
WHERE 
    mt.keyword_count > 0
ORDER BY 
    mt.production_year DESC,
    mt.title,
    da.actor_rank
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - **RankedTitles**: Ranks titles by year of production, creating a unique rank for each movie per year.
   - **MovieTitles**: Gathers title-related data along with associated company names and counts the number of unique keywords for each movie.
   - **DetailedActors**: Fetches actor names and assigns ranks within the context of their respective movies, counting total cast members.

2. **Complex Joins**:
   - Combines data across multiple tables using `LEFT JOIN` to keep all titles in the result set, even if they don't have associated companies or keywords.

3. **Window Functions**:
   - Uses `ROW_NUMBER()` to rank titles and actors, providing insights into ordering within groups.

4. **String Aggregation**:
   - Uses `STRING_AGG` to concatenate names of companies associated with each movie into a single string.

5. **Filtering and Pagination**:
   - The main query filters out movies with no keywords and implements pagination by skipping the first five results and fetching the next ten.

6. **Bizarre Logic**:
   - The conditions allow for the inclusion/exclusion of entries based on potentially obscure relationships among titles, keywords, and companies. 

This complex query serves both as a performance benchmark and a demonstration of advanced SQL techniques.
