WITH Recursive_CTE AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order,
        COALESCE(NULLIF(aka.name, ''), char.name) AS actor_name,
        COALESCE(NULLIF(aka.name, ''), char.name) IS NULL AS is_unknown_actor
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name aka ON ca.person_id = aka.person_id
    LEFT JOIN 
        char_name char ON ca.person_id = char.imdb_id
    WHERE 
        ca.nr_order IS NOT NULL
),
MaxRole_CTE AS (
    SELECT 
        person_id,
        MAX(role_order) AS max_role
    FROM 
        Recursive_CTE
    GROUP BY 
        person_id
),
Filmography AS (
    SELECT 
        r.actor_name,
        r.movie_id,
        m.title AS movie_title,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        mn.note AS movie_note,
        r.role_order,
        MAX(r.role_order) OVER (PARTITION BY r.actor_name) AS max_actor_role
    FROM 
        Recursive_CTE r
    LEFT JOIN 
        aka_title m ON r.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mn ON mn.movie_id = m.id AND mn.info_type_id IN (SELECT id FROM info_type WHERE info = 'Note')
    WHERE 
        r.role_order = (SELECT max_role FROM MaxRole_CTE WHERE person_id = r.person_id)
)
SELECT 
    f.actor_name,
    COUNT(f.movie_id) AS total_movies,
    STRING_AGG(f.movie_title, ', ' ORDER BY f.movie_title) AS movie_titles,
    STRING_AGG(DISTINCT f.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(f.movie_id) > 0 THEN 'Has films' 
        ELSE 'No films' 
    END AS film_status,
    AVG(f.max_actor_role) OVER () AS avg_role_position
FROM 
    Filmography f
GROUP BY 
    f.actor_name
HAVING 
    COUNT(f.movie_id) > 1
ORDER BY 
    total_movies DESC
LIMIT 10
OFFSET 5;

### Explanation
1. **Common Table Expressions (CTEs)**: 
   - `Recursive_CTE` extracts the relevant information from `cast_info`, joining with `aka_name` and `char_name`, while calculating the `role_order` for each actor and checking if their name is unknown.
   - `MaxRole_CTE` determines the maximum role order for each actor.
   - `Filmography` compiles the movie title and associated keywords along with notes for movies where the actor had the highest stated role.

2. **Window Functions**: 
   - `ROW_NUMBER()` assigns an order to roles by using ordering based on `nr_order`.
   - The `AVG()` function is used to calculate the average `max_actor_role` across all results.

3. **String Expressions**: 
   - `STRING_AGG` creates a concatenated list of movie titles and keywords, with ordering considered.

4. **Complicated Predicate/Expressions**: 
   - `COALESCE(NULLIF(...))` handles 'empty' values where necessary to ensure a valid name is selected.
   
5. **NULL Logic**: 
   - The checks on names to determine if they are NULL or empty drive conditional logic within queries.

6. **Set Operators**: Not specifically applied here, but concepts could be extended with UNION/INTERSECT if needed.

This query aims for detailed actor filmography, handling complexity in a clear and organized manner while also providing a real-world SQL scenario that's intricate yet insightful.
