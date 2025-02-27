WITH RECURSIVE MovieHierarchy AS (
    -- Get the top-level movies (e.g., movies without a parent episode)
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    -- Recursive part to get episodes of the movies
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
MovieCast AS (
    -- Get movie IDs along with the corresponding actor names
    SELECT 
        c.movie_id,
        ak.name AS actor_name
    FROM 
        cast_info c
    INNER JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
MovieInfo AS (
    -- Get additional info for movies including keywords
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        STRING_AGG(CASE WHEN mi.info_type_id = 1 THEN mi.info END, '; ') AS synopsis,
        STRING_AGG(CASE WHEN mi.info_type_id = 2 THEN mi.info END, '; ') AS notes
    FROM 
        movie_keyword m
    LEFT JOIN 
        keyword k ON m.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mc.actor_name,
    mi.keywords,
    mi.synopsis,
    ci.kind AS company_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_companies mc2 ON mh.movie_id = mc2.movie_id
LEFT JOIN 
    company_name cn ON mc2.company_id = cn.imdb_id
LEFT JOIN 
    company_type ci ON mc2.company_type_id = ci.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (mi.keywords IS NOT NULL OR mc.actor_name IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    mh.title,
    mc.actor_name;

This SQL query provides a detailed structure to benchmark performance by incorporating several advanced SQL features:

1. **Recursive CTEs**: The `MovieHierarchy` CTE creates a hierarchy of movies and their episodes.
2. **String Aggregation**: Uses `STRING_AGG` to combine keywords and synopses for concise output.
3. **Outer Joins**: Retrieves data across multiple tables, allowing for NULL handling where no data exists (e.g., missing keywords).
4. **Complex Filters**: Applies production year constraints and ensures either keywords or actor names exist.
5. **Order By Clause**: Orders results by production year and title for readability.

This allows for detailed analysis of movie data, especially useful for performance benchmarking on complex queries.
