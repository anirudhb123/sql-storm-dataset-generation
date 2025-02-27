WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Starting point for movies (not episodes)
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id  -- Recursive join to find episodes
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rc ON ci.role_id = rc.id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.movie_id) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(ci.movie_id) > 5  -- Only consider movies with more than 5 cast members
),
PopularMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        RANK() OVER (ORDER BY tm.cast_count DESC) AS popularity_rank
    FROM 
        TopMovies tm
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    COALESCE(ka.name, 'Unknown') AS lead_actor,
    COALESCE(kt.keyword, 'No Keywords') AS keywords
FROM 
    PopularMovies pm
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id AND ci.nr_order = 1  -- First ordered cast member
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    pm.popularity_rank <= 10 -- Get top 10 movies by cast count
ORDER BY 
    pm.cast_count DESC, 
    pm.title ASC;
This query consists of several parts:

1. **Recursive Common Table Expression (CTE):** Creates a hierarchy of movies and their episodes, starting from movies that are not episodes.

2. **Cast Info with Roles CTE:** Combines the cast information with their respective roles, while also ordering roles for each movie.

3. **TopMovies CTE:** Aggregates movie data to count how many cast members each movie has and filters to include only those with more than five cast members.

4. **PopularMovies CTE:** Ranks these popular movies based on their cast count.

5. **Final SELECT Statement:** Joins the popular movies with their lead actor and associated keywords to provide a comprehensive output, filtered to include only the top 10 movies.
