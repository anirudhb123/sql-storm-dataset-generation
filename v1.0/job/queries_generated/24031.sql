WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cd.actor_name,
    cd.role AS actor_role,
    mk.keywords,
    CASE 
        WHEN rm.cast_count > 5 THEN 'Featured'
        ELSE 'Supporting'
    END AS cast_type,
    COALESCE(NULLIF(mk.keywords, ''), 'No Keywords') AS processed_keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id AND cd.actor_rank <= 3
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id 
WHERE 
    rm.rank <= 10 AND 
    (rm.production_year IS NOT NULL AND rm.production_year > 2000)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

This SQL query performs several operations to retrieve a list of the top 10 movies produced after the year 2000, along with details about the top three actors for each movie. It also aggregates keywords associated with each movie using a string aggregation function, and it incorporates various SQL features including window functions, CTEs for organization, and the use of NULL handling and conditional expressions.

### Explanation of Key Elements:
- **CTEs (Common Table Expressions)**: 
  - `ranked_movies`: To get the movie's rank based on the count of actors in each production year.
  - `cast_details`: To retrieve actor details including their role and order in the cast.
  - `movie_keywords`: To aggregate keywords related to each movie.

- **Window Functions**: Used for ranking movies and actors.

- **Outer Join**: This was utilized to include movies that may not have any cast or keywords associated.

- **String Aggregation**: This allows combining keywords into a single string for each movie.

- **NULL Logic & CASE Statement**: For handling cases where there might be no keywords and categorizing the cast type based on the number of actors.

- **Complicated Predicates**: The WHERE clause filters by rank and ensures that the production year is valid, demonstrating advanced logic integration.

This query provides a comprehensive view while also showcasing an advanced understanding of SQL constructs.
