WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id = 1  -- Assuming '1' is for feature films
    GROUP BY 
        t.id, t.title, t.production_year
),

actor_details AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COALESCE(pi.info, 'No Info') AS personal_info,
        MAX(ci.id) AS max_cast_info_id
    FROM 
        aka_name p
    LEFT JOIN 
        person_info pi ON p.person_id = pi.person_id
    LEFT JOIN 
        cast_info ci ON p.person_id = ci.person_id
    WHERE 
        COALESCE(pi.info_type_id, 0) NOT IN (SELECT id FROM info_type WHERE info = 'Ignored')
    GROUP BY 
        p.id, p.name, pi.info
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    ad.name AS lead_actor,
    ad.personal_info
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON ad.max_cast_info_id = (
        SELECT MAX(ci.id)
        FROM cast_info ci
        WHERE ci.movie_id = rm.movie_id
    )
WHERE 
    rm.rank <= 5  -- Get top 5 movies per year
ORDER BY 
    rm.production_year, rm.actor_count DESC;
This query performs the following:
1. **Common Table Expressions (CTEs)** to separately rank movies based on the count of actors.
2. It retrieves detailed information about actors, including handling NULL logic through `COALESCE`.
3. Utilizes a correlated subquery to find details of the lead actor for each ranked movie.
4. Applies filtering to include only certain types of movies, selectively ignore personal info based on an inner query.
5. Sorts the final results to show top movies by actor count for each year.
