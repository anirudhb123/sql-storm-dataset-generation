WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorAwards AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT m.id) AS movie_count,
        SUM(CASE WHEN k.keyword = 'Oscar' THEN 1 ELSE 0 END) AS oscar_wins,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        cast_info c
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    WHERE 
        c.role_id IS NOT NULL
    GROUP BY 
        c.person_id
), 
TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        aa.movie_count,
        aa.oscar_wins,
        aa.keywords,
        RANK() OVER (ORDER BY aa.oscar_wins DESC, aa.movie_count DESC) AS award_rank
    FROM 
        aka_name a
    JOIN 
        ActorAwards aa ON a.person_id = aa.person_id
    WHERE 
        aa.movie_count > 0
)
SELECT 
    ta.name AS actor_name,
    ta.movie_count,
    ta.oscar_wins,
    ta.keywords,
    COALESCE((
        SELECT 
            COUNT(DISTINCT mc.company_id) 
        FROM 
            movie_companies mc 
        INNER JOIN 
            title t ON mc.movie_id = t.id 
        WHERE 
            t.production_year BETWEEN (SELECT MAX(production_year) FROM RankedMovies) - 5 AND (SELECT MAX(production_year) FROM RankedMovies)
            AND mc.note IS NULL
    ), 0) AS recent_movie_companies_count
FROM 
    TopActors ta
WHERE 
    ta.award_rank <= 10
ORDER BY 
    ta.award_rank;

### Explanation of SQL Query Components:

1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: This CTE ranks movies within each production year to filter out the most recent.
   - `ActorAwards`: This performs aggregation on `cast_info` to count movies and tally Oscar wins while also collecting keywords related to the actor. 

2. **LEFT JOINs**:
   - Used to join `cast_info` with `movie_keyword` to relate actors to movie keywords.

3. **Window Functions**:
   - `ROW_NUMBER()`: Used in `RankedMovies` to create a ranking based on year.
   - `RANK()`: Used in `TopActors` to rank actors by their Oscar wins and movie counts.

4. **String Aggregation**:
   - `STRING_AGG`: Gathers unique keywords into a comma-separated list.

5. **Correlated Subquery**:
   - The correlated subquery in the final SELECT provides a count of recent movie companies linked to the movies within the last five years of the highest production year.

6. **Complicated Predicates and Expressions**:
   - Utilizing various logical conditions and aggregations ensures complex predicates.

7. **COALESCE**: 
   - To handle potential NULL values effectively.

This SQL query collectively provides a thorough dynamic view of top actors based on movie participation and awards, framed elegantly within the complexities of SQL mechanics.
