WITH RECURSIVE movie_series AS (
    SELECT t.id AS movie_id, t.title, 
           t.production_year, 
           COALESCE(t.season_nr, 0) AS season_nr, 
           COALESCE(t.episode_nr, 0) AS episode_nr,
           RANK() OVER (PARTITION BY t.season_nr ORDER BY t.episode_nr) AS episode_rank
    FROM aka_title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'tv series')
),
cast_details AS (
    SELECT c.id AS cast_id, 
           a.name AS actor_name, 
           t.title, 
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.id
),
movie_info_extended AS (
    SELECT m.id AS movie_id, 
           m.title, 
           COALESCE(STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL), 'No Keywords') AS keywords,
           COUNT(i.id) AS info_count,
           AVG(LENGTH(i.info)) AS avg_info_length
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id 
    LEFT JOIN keyword k ON mk.keyword_id = k.id 
    LEFT JOIN movie_info i ON m.id = i.movie_id
    WHERE m.production_year > 2000
    GROUP BY m.id
)
SELECT ms.movie_id,
       ms.title,
       ms.production_year,
       ms.season_nr,
       ms.episode_nr,
       CASE 
           WHEN ms.episode_rank IS NULL THEN 'Standalone Movie'
           ELSE 'Part of Series'
       END AS series_status,
       COALESCE(cd.actor_name, 'No Cast') AS main_actor,
       m.keywords,
       m.info_count,
       m.avg_info_length
FROM movie_series ms
FULL OUTER JOIN cast_details cd ON ms.movie_id = cd.movie_id
FULL OUTER JOIN movie_info_extended m ON ms.movie_id = m.movie_id
WHERE (ms.season_nr = 0 OR ms.season_nr IS NULL)
  AND (cd.role_order = 1 OR cd.role_order IS NULL)
ORDER BY ms.production_year DESC, 
         ms.title ASC NULLS LAST;

### Query Explanation:
1. **Common Table Expressions (CTEs)**:
   - `movie_series` uses a recursive CTE to fetch titles that are part of a TV series, aggregating episodes based on their seasons.
   - `cast_details` fetches cast information, with ordering for each role to understand leading roles.
   - `movie_info_extended` fetches additional movie information such as associated keywords and info count, with checks on production year.

2. **Main Select**:
   - The main query selects relevant information from the derived CTEs, performing a `FULL OUTER JOIN` to ensure we capture all potential matches, including movies without cast or additional info.
   - The `CASE` statement is used to indicate whether a movie is standalone or part of a series.

3. **Join Logic**:
   - A combination of `FULL OUTER JOIN` ensures that if there are movies without cast or info, they still appear in the results.

4. **Complicated Filtering and Order**:
   - The use of predicates such as checking for `NULL` or specific order conditions adds complexity.
   - The `ORDER BY` at the end organizes results by production year and title, managing NULLs gracefully.
  
### Additional Features:
- Utilization of string aggregation (`STRING_AGG`) and complex filtering with `FILTER` and `COALESCE` for handling potential NULLs and providing defaults where appropriate.
- Rank and row functions to calculate order of episodes and main roles without directly specifying roles or ranks in the main join clause, allowing for flexibility in determining lead actors.
