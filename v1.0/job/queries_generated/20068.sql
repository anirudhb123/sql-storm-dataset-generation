WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY mci.company_id DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mci ON t.id = mci.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title NOT LIKE '%%  --  %'   -- Exclude bizarre titles containing ' -- '
),
ActorInfo AS (
    SELECT 
        ak.person_id,
        ak.name,
        COALESCE(ca.note, 'No role specified') AS role_note,
        CASE 
            WHEN ri.rank IS NOT NULL THEN ri.rank
            ELSE 'Not ranked'
        END AS rank_status
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ca ON ak.person_id = ca.person_id
    LEFT JOIN 
        (
            SELECT 
                c.id AS person_id,
                DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
            FROM 
                aka_name c
            LEFT JOIN 
                cast_info ci ON c.person_id = ci.person_id
            GROUP BY 
                c.id
        ) ri ON ak.person_id = ri.person_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ai.name AS actor_name,
    ai.role_note,
    ai.rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = rm.movie_id 
          AND ci.person_id = ai.person_id 
          AND coalesce(ai.role_note, 'No role specified') NOT LIKE 'No role%'
    )
WHERE 
    rm.year_rank <= 3 
    AND (ai.name IS NULL OR ai.role_note IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.movie_id;

### Explanation:

1. **CTE RankedMovies**: We generate a ranking for movies made each year based on the descending order of company IDs associated with the movies. This allows us to find the top ranked movies per year.

2. **CTE ActorInfo**: We join the `aka_name` and `cast_info` tables to get details about actors and their roles. The CTE uses a `DENSE_RANK` window function to rank actors based on the number of unique movies they are associated with. If an actor is not associated with any roles, they receive a default note.

3. **Final Selection**: We then select from `RankedMovies` while left joining `ActorInfo`. The join condition uses an `EXISTS` clause to ensure that actors are participating in the movie and adds additional logic to handle NULLs properly.

4. **Predicates**: The query enforces multiple conditions:
    - It limits the movies selected to the top 3 ranked movies per year.
    - It also includes a NULL check to show movies with no actors associated or requiring their role.

5. **ORDER BY**: Finally, the results are ordered by `production_year` descending and movie ID.

This query is designed to showcase SQL features including CTEs, window functions, outer joins, and intricate conditionals with a focus on potential performance benchmarking due to its complexity and multi-layered structure.
