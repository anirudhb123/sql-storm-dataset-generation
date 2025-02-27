WITH RECURSIVE movie_series AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.season_nr,
        t.episode_nr,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL 
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.season_nr,
        t.episode_nr,
        ms.depth + 1
    FROM 
        aka_title t
    JOIN 
        movie_series ms ON t.episode_of_id = ms.movie_id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS details
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id AND mi.info_type_id = mii.info_type_id
    WHERE 
        mi.info IS NOT NULL OR mii.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)

SELECT 
    m.title AS movie_title,
    md.depth AS series_depth,
    ad.actor_name,
    ad.role_order,
    COALESCE(mk.keywords, ARRAY[]::text[]) AS keywords,
    COALESCE(mid.details, 'No additional info') AS additional_info
FROM 
    movie_series md
LEFT JOIN 
    actor_details ad ON md.movie_id = ad.movie_id
LEFT JOIN 
    movie_keywords mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_details mid ON md.movie_id = mid.movie_id
WHERE 
    (md.season_nr IS NULL OR md.season_nr > 0)
    AND (ad.role_order IS NOT NULL OR ad.actor_name IS NULL)
    AND (md.depth <= 3 OR md.depth IS NULL)
ORDER BY 
    md.title, ad.role_order
LIMIT 100 OFFSET 0;

This SQL query performs the following:

1. **CTE for Movie Series**: Recursively retrieves movies and their corresponding episodes while maintaining a depth count for series, which helps in identifying the layers of a series.
   
2. **Actor Details**: It captures actors along with their roles in a specific movie, using window functions to order roles of each actor.

3. **Keyword Aggregation**: Collects all distinct keywords associated with each movie into an array.

4. **Movie Info Details**: Gathers additional information related to movies, aggregating the details into a single string per movie.

5. **Final Selection**: Combines data from all CTEs to produce a normalized output, including titles, actors, keywords, depth, and additional info while applying various filtering predicates, including NULL handling and conditional depth logic. 

6. **Ordering and Limiting**: The query orders the results by movie title and actor role order, returning the first 100 records. 

The complexity of the query engages various SQL features, illustrating the powerful querying capabilities while navigating semantic caveats—particularly regarding NULL handling, recursion, and aggregates/types.
