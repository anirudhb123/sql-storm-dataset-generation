WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(e.season_nr, 0) AS season,
        COALESCE(e.episode_nr, 0) AS episode,
        CAST(NULL AS INTEGER) AS parent_id,
        0 AS depth
    FROM 
        aka_title m
    LEFT JOIN aka_title e ON m.episode_of_id = e.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        COALESCE(gr.season_nr, 0),
        COALESCE(gr.episode_nr, 0),
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM 
        aka_title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
)
, popular_movies AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, '; ') AS top_cast
    FROM 
        cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    WHERE 
        c.nr_order < 5
    GROUP BY 
        c.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.season,
    mh.episode,
    pm.total_cast,
    pm.top_cast,
    COALESCE(mi.info, 'N/A') AS movie_info,
    CASE 
        WHEN pm.total_cast IS NULL THEN 'No Cast Info'
        WHEN pm.total_cast > 10 THEN 'Highly Popular'
        ELSE 'Moderate Popularity'
    END AS popularity_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    popular_movies pm ON mh.movie_id = pm.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Plot', 'Synopsis'))
ORDER BY 
    mh.production_year DESC,
    mh.title ASC
FETCH FIRST 100 ROWS ONLY;

This SQL query employs multiple advanced features:
1. **CTEs (Common Table Expressions)**: One for movie hierarchy and another for calculating popular movies based on cast count.
2. **Jointures**: Utilizes outer joins to incorporate potential missing data (e.g., episodes without a parent movie).
3. **Window Functions**: `STRING_AGG` to concatenate the names of the cast for a movie.
4. **Conditional Logic**: Uses a `CASE` statement to classify the films based on the total cast count.
5. **Subqueries**: Implemented within both the main query and to derive the movie information type IDs.
6. **Complex predicates**: Filtering based on role order and movie types.
7. **NULL Logic**: Handle cases where information might not be present, ensuring robust output.
8. **ORDER BY and FETCH**: Providing a structured output limited to the top 100 most recent films.
