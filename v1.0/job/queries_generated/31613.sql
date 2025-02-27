WITH RECURSIVE Actor_Bio AS (
    SELECT 
        ci.person_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS movie_rank,
        COALESCE(ci.note, 'No Role Info') AS role_note
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
), 
Company_Movie AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ab.actor_name,
    ab.movie_title,
    ab.production_year,
    ab.movie_rank,
    cm.companies,
    cm.company_count,
    (SELECT COUNT(*)
     FROM cast_info ci_sub
     WHERE ci_sub.movie_id = ab.movie_id AND ci_sub.person_id <> ab.person_id) AS co_actors_count,
    CASE 
        WHEN ab.role_note IS NULL THEN 'Unknown Role'
        ELSE ab.role_note
    END AS role_description
FROM 
    Actor_Bio ab
LEFT JOIN 
    Company_Movie cm ON ab.movie_id = cm.movie_id
WHERE 
    ab.movie_rank <= 5
ORDER BY 
    ab.production_year DESC, ab.actor_name;

### Explanation:

1. **CTEs (Common Table Expressions)**:
   - **Actor_Bio**: This CTE gathers information about actors, including their names, the titles of the movies they've appeared in, production years, ranks based on production year, and their role notes. It generates a row for each movie the actor has participated in, ordered by production year.
   - **Company_Movie**: This CTE aggregates the companies associated with each movie, counting them and concatenating their names.

2. **Main SELECT Query**:
   - Joins the results from the `Actor_Bio` and `Company_Movie` CTEs based on the movie ID.
   - Splits the final output into specific columns, including handling potential NULLs with `CASE`, counting co-actors for each movie using a correlated subquery, and restricting results to the top 5 movies for each actor based on the sort order.

3. **Window Functions**: `ROW_NUMBER()` is used in the `Actor_Bio` CTE to rank movies for each actor.

4. **String Aggregation**: `GROUP_CONCAT` is utilized in the `Company_Movie` CTE to create a list of company names for each movie.

5. **NULL Logic**: A `CASE` statement ensures graceful handling of null role notes, providing a default description when needed.

6. **Ordering**: The results are ordered by `production_year` in descending order and `actor_name`.

This query can be used for performance benchmarking due to its complexity and various SQL features employed.
