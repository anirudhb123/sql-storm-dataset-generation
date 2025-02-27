WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
),

filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        rc.actor_name,
        rc.actor_rank,
        rc.total_actors,
        COALESCE(kw.keyword, 'No Keyword') AS movie_keyword
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
)

SELECT 
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.actor_rank,
    fm.total_actors,
    CASE 
        WHEN fm.actor_name IS NULL THEN 'No Cast Found'
        ELSE CONCAT(fm.actor_name, ' (Rank ', fm.actor_rank, ' of ', fm.total_actors, ')')
    END AS actor_info,
    COUNT(*) OVER (PARTITION BY fm.production_year) AS movies_in_year
FROM 
    filtered_movies fm
WHERE 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, 
    fm.actor_rank;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: This CTE builds a hierarchy of movies and their episodes, selecting only the top-level movies (those without an `episode_of_id`).

2. **Ranked Cast (`ranked_cast`)**: This CTE ranks actors for each movie and counts the total number of actors in each movie using window functions (e.g., `ROW_NUMBER` and `COUNT`).

3. **Filtered Movies (`filtered_movies`)**: Combines the previous CTEs and gathers additional information like keywords. A left join is used to include all movies, even if they don't have keywords.

4. **Final SELECT**: The main query selects relevant columns from the filtered data, applies case logic to handle nulls and formats actor information neatly. It calculates the total number of movies per production year (using another window function).

5. **WHERE Clause**: Filters the movies to show only those produced after the year 2000, and the results are ordered by production year in descending order, followed by actor rank.
