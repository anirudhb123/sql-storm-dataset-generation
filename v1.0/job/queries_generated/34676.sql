WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
CastWithRank AS (
    SELECT 
        ci.movie_id,
        p.id AS person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
        AND pi.info IS NOT NULL
),
MovieKeywords AS (
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
    mh.production_year,
    COALESCE(cwr.actor_name, 'Unknown Actor') AS main_actor,
    mh.parent_movie_id,
    mh.level,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastWithRank cwr ON mh.movie_id = cwr.movie_id AND cwr.rank = 1
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND (cwr.actor_name IS NOT NULL OR mh.level > 1)
ORDER BY 
    mh.production_year DESC,
    mh.title;

This SQL query performs the following operations:
1. **Common Table Expressions (CTEs)**: It establishes a recursive CTE (`MovieHierarchy`) to derive a hierarchy of movies and episodes, allowing to trace the lineage of episodes back to their respective parent movies.
   
2. **Window Functions**: Utilizes `ROW_NUMBER()` in `CastWithRank` to rank the cast members based on their order in the 'cast_info' table for each movie.

3. **Aggregate Functions**: Uses `STRING_AGG()` to combine all keywords associated with each movie in the `MovieKeywords` CTE.

4. **Outer Joins**: Uses `LEFT JOIN` to ensure that if there are no actors or keywords associated with a movie, the hierarchy and title still appear.

5. **Coalescing NULL values**: Employs `COALESCE` to substitute default values for missing actors and keywords.

6. **Filtering and Sorting**: It filters results to include only movies produced from the year 2000 onwards and sorts the output by production year and title.

Overall, this query combines multiple advanced SQL techniques to offer a detailed and hierarchical view of movies and their relationships alongside relevant cast information and keywords.
