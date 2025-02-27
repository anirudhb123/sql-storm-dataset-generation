WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
recent_movies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year
    FROM 
        movie_info mt
    WHERE 
        mt.info_type_id = (SELECT id FROM info_type WHERE info = 'released')
        AND mt.info = 'Yes'
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    rm.title,
    rm.production_year,
    cd.cast_count,
    cd.actor_names,
    COALESCE(mh1.title, 'N/A') AS parent_movie_title
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_hierarchy mh1 ON rm.movie_id = mh1.movie_id AND mh1.level > 1
WHERE 
    rm.movie_rank <= 10
    AND rm.movie_id IN (SELECT movie_id FROM recent_movies)
ORDER BY 
    rm.production_year DESC;

### Explanation:
1. **CTE `movie_hierarchy`:** Recursively fetches movie titles and their production years, forming a hierarchy based on linked movies.
2. **CTE `cast_details`:** Aggregates counts and names of actors in each movie.
3. **CTE `recent_movies`:** Filters recently released movies based on info type.
4. **CTE `ranked_movies`:** Ranks movies based on their production years for the hierarchy levels.
5. **Final SELECT:** Combines the results from the CTEs using outer joins and formats the output to include parent movie titles where applicable. The query limits results and orders by recent productions.
