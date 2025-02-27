WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select top-level movies (no episode_of_id)
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    -- Recursive case: Select episodes of the movies
    SELECT 
        ae.id AS movie_id,
        ae.title,
        mh.level + 1
    FROM 
        aka_title ae
    JOIN 
        movie_hierarchy mh ON ae.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    keyword_summary ks ON mh.movie_id = ks.movie_id
ORDER BY 
    mh.level DESC, mh.title;

### Explanation:
1. **CTE for Movie Hierarchy**: The recursive Common Table Expression (CTE) `movie_hierarchy` derives a hierarchy of movies, extracting those that are either standalone or are episodes of other movies.

2. **Details of Cast Members**: The `cast_details` CTE gathers the total cast count per movie and lists the names of the cast.

3. **Keywords Associated with Movies**: The `keyword_summary` CTE collects keywords related to each movie.

4. **Final Query**: The main SELECT statement combines the results of the three CTEs using LEFT JOINs to ensure even movies without casts or keywords will still appear in the final output. It utilizes COALESCE to handle NULL values elegantly, providing defaults where necessary. The results are ordered by the movie hierarchy level (to show top-level movies first) and then by the title.
