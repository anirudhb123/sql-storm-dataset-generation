WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY a.name) AS actor_rank
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year >= 2000
),

notable_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_type,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM movie_hierarchy
    GROUP BY movie_id, title, production_year, company_type
)

SELECT 
    nm.movie_id,
    nm.title,
    nm.production_year,
    nm.company_type,
    nm.actors,
    nm.keywords,
    (SELECT COUNT(*) 
     FROM movie_link ml 
     WHERE ml.movie_id = nm.movie_id) AS linked_movies_count,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = nm.movie_id 
       AND cc.subject_id IS NULL) AS incomplete_cast_count,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = nm.movie_id AND mi.info_type_id IS NULL) 
        THEN 'Missing Info' 
        ELSE 'All Info Present' 
    END AS info_status
FROM notable_movies nm
WHERE nm.company_type IS NOT NULL
ORDER BY nm.production_year DESC, nm.title
LIMIT 100;

### Query Breakdown:
1. **CTEs (Common Table Expressions)**: 
    - `movie_hierarchy`: Builds a recursive structure that pulls together information from multiple tables for movies produced after 2000.
    - `notable_movies`: Aggregates actor names and keywords for each movie.

2. **LEFT JOINs**: Utilized in way to ensure no records are lost when there are missing associations (e.g., no company or no actors).

3. **STRING_AGG**: Collects actor names and keywords into a single string, separated by commas.

4. **Subqueries**: 
    - One subquery counts the number of linked movies, while another counts incomplete casts.
    - Both use `SELECT COUNT(*) FROM;` to derive counts directly connected to the `movie_id`.

5. **CASE**: Evaluates the existence of entries in `movie_info` without an associated `info_type_id` and labels the info status accordingly.

6. **COALESCE**: Provides default names when join results in NULL, ensuring complete data representation.

7. **Bizarre SQL Semantics**: 
    - The use of `ROW_NUMBER()` allows a unique ranking of actors per movie, bringing a nuanced touch to the results.
    - Attempting to aggregate information on "incomplete casts" while leveraging outer joins highlights the intricacies of relational structures.

8. **Final Selection**: The final output is ordered by production year and limited to 100 entries for performance benchmarking.
