WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) OVER(PARTITION BY a.id) AS actor_count,
        RANK() OVER(ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_count
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
),

TitleKeyword AS (
    SELECT
        t.title,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
),

CriticalInfo AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT ci.info) AS info_count,
        LISTAGG(ci.info, ', ') WITHIN GROUP (ORDER BY ci.info) AS concatenated_info
    FROM complete_cast cc
    JOIN movie_info mi ON cc.movie_id = mi.movie_id
    JOIN info_type it ON mi.info_type_id = it.id
    JOIN title t ON cc.movie_id = t.id
    JOIN movie_info_idx mii ON t.id = mii.movie_id
    WHERE it.info IS NOT NULL AND LENGTH(it.info) > 0
    GROUP BY c.movie_id
)

SELECT 
    a.name,
    t.title,
    tm.actor_count,
    tm.production_year,
    COALESCE(ki.keyword, 'No Keywords') AS keyword,
    ci.info_count,
    ci.concatenated_info,
    CASE 
        WHEN ci.info_count IS NULL THEN 'No Info'
        ELSE 'Info Available' 
    END AS info_status,
    rng.rank_count
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN RankedMovies tm ON c.movie_id = tm.id
LEFT JOIN TitleKeyword ki ON tm.title = ki.title AND ki.keyword_rank = 1
LEFT JOIN CriticalInfo ci ON tm.id = ci.movie_id
LEFT JOIN (SELECT DISTINCT movie_id, COUNT(*) AS rank_count FROM movie_info GROUP BY movie_id) rng ON tm.id = rng.movie_id
WHERE a.name IS NOT NULL
ORDER BY tm.actor_count DESC, ci.info_count DESC NULLS LAST, a.name;

### Explanation:
- **CTE (Common Table Expressions)**:
  - `RankedMovies`: Determines the number of unique actors per movie and ranks them accordingly.
  - `TitleKeyword`: Captures the keywords associated with movies, ranking them per movie title.
  - `CriticalInfo`: Collects critical information associated with movies and concatenates it while counting the distinct entries.
  
- **Core SELECT**:
  - Retrieves names from `aka_name`, along with the corresponding titles and other details obtained from the join with multiple CTEs.
  
- **Joins**:
  - Uses `LEFT JOIN` to include records even when specific conditions aren't met (i.e., movies without actors or keywords).
  
- **Window Functions**:
  - `COUNT` for calculating actor counts per movie and `RANK` for determining rank counts in `RankedMovies`.
  
- **String Aggregation**:
  - `LISTAGG` is employed in `CriticalInfo` to create a concatenated string of information records from associated movies.

- **NULL Logic**:
  - The `COALESCE` function handles cases where there's no keyword data, while the `CASE` statement evaluates the presence of critical info.

- **Order**:
  - Finally, results are sorted by the number of actors, information count (with NULLs last), and the name alphabetically. 

This SQL query is designed to explore the schema in-depth and illustrate the complex interactions and relationships present within the data.
