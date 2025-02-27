WITH Recursive_Cast AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ca ON a.person_id = ca.person_id
    LEFT JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    GROUP BY 
        a.person_id
), 
Ranked_Movies AS (
    SELECT 
        rc.person_id,
        rc.movie_count,
        rc.movie_titles,
        RANK() OVER (ORDER BY rc.movie_count DESC, rc.person_id) AS movie_rank
    FROM 
        Recursive_Cast rc
),
Top_Actors AS (
    SELECT 
        r.person_id,
        r.movie_count,
        r.movie_titles
    FROM 
        Ranked_Movies r
    WHERE 
        r.movie_count > (
            SELECT AVG(movie_count) FROM Ranked_Movies
        )
)

SELECT 
    a.name AS actor_name,
    ta.movie_count,
    ta.movie_titles,
    COALESCE(
        (SELECT COUNT(*)
         FROM movie_info mi 
         WHERE 
             mi.movie_id IN (SELECT DISTINCT movie_id FROM cast_info ci WHERE ci.person_id = ta.person_id)
             AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Cinematography')), 
        0) AS cinematography_count,
    CASE 
        WHEN ta.movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM 
    aka_name a
JOIN 
    Top_Actors ta ON a.person_id = ta.person_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
WHERE 
    (pi.info IS NULL OR pi.info LIKE '%1990%') -- actors born in 1990 or without birthdate
ORDER BY 
    ta.movie_count DESC, actor_name;

### Explanation of the Query:

1. **Common Table Expressions (CTEs)**: 
   - `Recursive_Cast`: This calculates the total number of movies for each actor based on their `person_id`, along with a string aggregation of their movie titles.
   - `Ranked_Movies`: Ranks actors based on their movie count using the `RANK()` window function.
   - `Top_Actors`: Filters actors who have a movie count greater than the average count of all ranked actors.

2. **Main Query**: 
   - Joins the `aka_name` table with the `Top_Actors` CTE to get actor names and their movie details.
   - Counts the number of movies where cinematographers were involved, demonstrating a correlated subquery that links `movie_info` with `cast_info`.
   - Using a `CASE` statement to classify actors based on their movie count.

3. **Filter Logic**: 
   - Filters for actors either born in 1990 or without a provided birthdate, thereby demonstrating NULL logic.

4. **Order Clause**: 
   - The results are ordered by the number of movies descending and actor names alphabetically.

This query is complex, involves multiple SQL concepts, and uses both correlated and non-correlated subqueries, joins, window functions, and string operations effectively while posing unusual yet common logical semantics typical in real-world data scenarios.
