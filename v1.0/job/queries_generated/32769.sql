WITH RECURSIVE hierarchical_movies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title at
    JOIN 
        title mt ON at.movie_id = mt.id
    WHERE 
        mt.kind_id = 1  -- Assuming 1 corresponds to movies

    UNION ALL

    SELECT 
        lm.linked_movie_id,
        lmt.title,
        lmt.production_year,
        hm.depth + 1
    FROM 
        movie_link lm
    JOIN 
        title lmt ON lm.linked_movie_id = lmt.id
    JOIN 
        hierarchical_movies hm ON lm.movie_id = hm.movie_id
    WHERE 
        lm.link_type_id = 2  -- Assuming 2 corresponds to "related to"
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
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
    hm.movie_id,
    hm.title,
    hm.production_year,
    COALESCE(rc.actor_name, 'No Actors') AS main_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    hm.depth AS linked_depth
FROM 
    hierarchical_movies hm
LEFT JOIN 
    ranked_cast rc ON hm.movie_id = rc.movie_id AND rc.actor_rank = 1
LEFT JOIN 
    movie_keywords mk ON hm.movie_id = mk.movie_id
WHERE 
    hm.production_year >= 2000
ORDER BY 
    hm.production_year DESC, 
    hm.title;

### Explanation:
1. **Recursive CTE (`hierarchical_movies`)**: This part retrieves movies and their linked movies recursively.
2. **Ranking Actors (`ranked_cast`)**: The `ranked_cast` CTE collects actors for each movie and ranks them by their order in the cast list. 
3. **Aggregating Keywords (`movie_keywords`)**: This CTE fetches all keywords for each movie and concatenates them into a single string.
4. **Main Query**: Combines the recursive list of movies, their main actor (if available), and their associated keywords using outer joins, filtering for movies produced after 2000.
5. **COALESCE**: This is used to handle NULL cases for actors or keywords, providing default text if they are not available.
6. **ORDER BY**: Orders the results by production year and title.

This query demonstrates a comprehensive SQL structure using various constructs while also being effective for performance benchmarking.
