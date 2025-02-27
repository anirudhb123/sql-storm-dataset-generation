WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actor_names,
        COALESCE(mn.info, 'No extra info') AS movie_note,
        COALESCE(mi.info, 'N/A') AS extra_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mn ON rm.movie_id = mn.movie_id AND mn.info_type_id IN (SELECT id FROM info_type WHERE info = 'Note')
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
    WHERE 
        rm.production_year BETWEEN 1990 AND 2023
),
FinalOutput AS (
    SELECT 
        mwi.movie_id,
        mwi.title,
        mwi.production_year,
        mwi.total_cast,
        mwi.actor_names,
        mwi.movie_note,
        mwi.extra_info,
        DENSE_RANK() OVER (ORDER BY mwi.total_cast DESC) AS rank_by_cast
    FROM 
        MoviesWithInfo mwi
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.total_cast,
    fo.actor_names,
    fo.movie_note,
    fo.extra_info,
    fo.rank_by_cast,
    COUNT(DISTINCT cm.company_id) AS company_count,
    MAX(gk.keyword) AS most_common_keyword
FROM 
    FinalOutput fo
LEFT JOIN 
    movie_companies mc ON fo.movie_id = mc.movie_id
LEFT JOIN 
    keyword gk ON fo.movie_id = gk.id
LEFT JOIN 
    (SELECT movie_id, COUNT(*) as cnt FROM movie_keyword GROUP BY movie_id) mk ON fo.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, GROUP_CONCAT(DISTINCT tk.keyword) AS keywords FROM movie_keyword tk GROUP BY movie_id) as tokens ON fo.movie_id = tokens.movie_id
WHERE 
    fo.rank_by_cast < 10 
GROUP BY 
    fo.movie_id, fo.title, fo.production_year, fo.total_cast, fo.actor_names, fo.movie_note, fo.extra_info
ORDER BY 
    fo.production_year DESC, fo.rank_by_cast;

### Query Breakdown
- **CTEs** used:
  - `RankedMovies`: Determines the total number of distinct actors per movie and ranks them within their production year.
  - `MoviesWithInfo`: Fetches additional information linked to the movies, including notes and extra info, using `LEFT JOIN` with `COALESCE` to handle NULL values.
  - `FinalOutput`: Combines gathered data and calculates a rank based on the number of actors.
  
- **Outer Joins**: The query utilizes `LEFT JOIN` to ensure that movies that might not have associated data (like extra info or companies) are still included in the results.

- **Window Functions**: The use of `ROW_NUMBER()` for ranking movies and `DENSE_RANK()` for ordering the final output by the number of cast members.

- **Bizarre SQL Semantics**: Uses subqueries in the `ON` clause and considers corner cases like `COALESCE` to provide default values for NULLs.

- **Set Operators**: The aggregate functions and strings utilize `STRING_AGG` and `GROUP_CONCAT`, while `COUNT(DISTINCT ...)` is employed for counting discrete entries.

- **Complicated Predicates/Calculations**: Multiple `WHERE` and `GROUP BY` clauses make the computation of ranks and counts more complex, allowing for significant flexibility in results.

- **STRING Expressions**: The use of `STRING_AGG` for concatenating actor names gives a comprehensive view of the cast involved.

This SQL is suitable for performance benchmarking due to its intricate joins, window functions, and aggregations, which can test the database engine's capacity to handle complex queries efficiently.
