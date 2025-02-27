WITH Recursive_Actor_Movies AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        aka_title at ON ca.movie_id = at.id
    WHERE 
        a.name IS NOT NULL AND at.production_year IS NOT NULL
),
Popular_Actors AS (
    SELECT 
        actor_name, 
        COUNT(movie_title) AS total_movies
    FROM 
        Recursive_Actor_Movies
    WHERE 
        movie_rank <= 5
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) >= 3
),
Movies_With_Keywords AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
),
Highest_Rated_Movies AS (
    SELECT 
        at.title AS movie_title,
        mia.info AS movie_rating
    FROM 
        aka_title at
    JOIN 
        movie_info mia ON at.id = mia.movie_id
    WHERE 
        mia.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
)
SELECT 
    p.actor_name,
    p.total_movies,
    m.movie_title,
    m.keywords,
    hr.movie_rating
FROM 
    Popular_Actors p
JOIN 
    Recursive_Actor_Movies ram ON p.actor_name = ram.actor_name
LEFT JOIN 
    Movies_With_Keywords m ON ram.movie_title = m.title
LEFT JOIN 
    Highest_Rated_Movies hr ON ram.movie_title = hr.movie_title
WHERE 
    ram.movie_rank <= 5
    AND (hr.movie_rating IS NULL OR hr.movie_rating::FLOAT > 8.0)
ORDER BY 
    p.total_movies DESC, 
    ram.production_year DESC
LIMIT 10;

### Explanation of Constructs Used:
1. **Common Table Expressions (CTEs)**:
   - `Recursive_Actor_Movies`: Ranks movies for each actor and filters out any NULL names or production years.
   - `Popular_Actors`: Identifies actors who have been in 3 or more movies within the top 5 ranked by year.
   - `Movies_With_Keywords`: Aggregates keywords for each movie using a string aggregation technique.
   - `Highest_Rated_Movies`: Pulls movies alongside their ratings by matching against an `info_type`.

2. **Window Functions**:
   - `ROW_NUMBER()` to assign a rank to each movie based on the production year for each actor.
  
3. **String Aggregation**:
   - `STRING_AGG()` is utilized to aggregate movie keywords into a single, comma-separated string.

4. **Outer Joins**:
   - A `LEFT JOIN` allows for capturing keywords even if some movies do not have any associated keywords.

5. **Complicated Predicates**:
   - Utilizes conditions to filter based on either absence of ratings or a specific threshold of ratings (greater than 8.0).

6. **NULL Logic**: 
   - It checks whether the movie rating is NULL, illustrating how to manage cases where ratings might not exist.

7. **Bizarre Semantics**: 
   - The query applies various NULL checks intertwined with hold-on logic on actor counts and specific rating filters, ensuring it captures and excludes certain rows effectively.

This query serves to benchmark joins, aggregations, filtering, and CTE usage while maintaining complexity and operational integrity.
