WITH Recursive_Actor_Movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ct.kind AS role,
        m.title AS movie_title,
        m.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    JOIN 
        comp_cast_type ct ON c.role_id = ct.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL 

    SELECT 
        ra.actor_id,
        ra.actor_name,
        ra.role,
        second_m.title AS movie_title,
        second_m.production_year
    FROM 
        Recursive_Actor_Movies ra
    JOIN 
        cast_info ci ON ra.actor_id = ci.person_id
    JOIN 
        aka_title second_m ON ci.movie_id = second_m.movie_id
    WHERE 
        second_m.production_year > ra.production_year
),
Filtered_Movies AS (
    SELECT 
        actor_id, 
        actor_name, 
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_list
    FROM 
        Recursive_Actor_Movies
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(DISTINCT movie_title) > 2
)
SELECT 
    f.actor_id,
    f.actor_name,
    f.movie_count,
    f.movie_list,
    COALESCE(k.keyword, 'No keyword') AS movie_keyword,
    CASE 
        WHEN f.movie_count > 10 THEN 'Prolific Actor'
        WHEN f.movie_count BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Occasional Actor'
    END AS actor_category
FROM 
    Filtered_Movies f
LEFT JOIN 
    movie_keyword mk ON f.actor_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    f.actor_name NOT LIKE '%Smith%' -- Excluding actors with 'Smith' in their name
    AND f.movie_count IS NOT NULL
ORDER BY 
    f.movie_count DESC;

This query includes:

1. **CTE**: The `Recursive_Actor_Movies` CTE recursively fetches movies for actors, which is useful in analyzing the complete work of an actor in relation to their filmography.
2. **JOINs**: Multiple outer joins with the `cast_info`, `aka_title`, and `comp_cast_type` tables to correlate actors with their movie roles, demonstrating intricate joins.
3. **Filtering**: A `HAVING` clause to only return actors with more than 2 movies, ensuring focus on prolific contributors.
4. **Aggregation**: `STRING_AGG` for concatenating movie titles into a single string.
5. **Logic and Categories**: Use of `CASE` statement to categorize actors based on their filmography looks into both NULL logic and normal distribution considerations among actor counts.
6. **LEFT JOINs with COALESCE**: To extract potential keywords associated with movies while providing a default value for cases where no keyword exists.
7. **Unusual Semantics**: Exclusion of actors with 'Smith' in their name as a means to show how complex filter conditions can alter dataset results interestingly.

This SQL demonstrates both the complexity and utility of advanced SQL features for analyzing data in an entertainment database context.
