WITH Recursive MovieHierarchy AS (
    -- CTE to construct a hierarchy of movies and their linked counterparts
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
),
DistinctKeywords AS (
    -- CTE to aggregate distinct keywords for movies
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinishedMovies AS (
    -- CTE to prepare the final dataset of movies with information
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE((SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id), 0) AS number_of_cast,
        COALESCE((SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = t.id), 0) AS number_of_companies
    FROM 
        title t
    LEFT JOIN 
        DistinctKeywords k ON t.id = k.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND (t.kind_id IS NOT NULL AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'tvmovie')))
),
FinalReport AS (
    -- Final reporting table with all necessary calculations and data
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.keywords,
        fm.number_of_cast,
        fm.number_of_companies,
        mh.depth AS link_depth
    FROM 
        FinishedMovies fm
    LEFT JOIN 
        MovieHierarchy mh ON fm.movie_id = mh.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keywords,
    fr.number_of_cast,
    fr.number_of_companies,
    MAX(fr.link_depth) AS max_link_depth
FROM 
    FinalReport fr
GROUP BY 
    fr.movie_id, fr.title, fr.production_year, fr.keywords, fr.number_of_cast, fr.number_of_companies
HAVING 
    MAX(fr.link_depth) IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title;

### Query Explanation:

1. **Recursive CTE `MovieHierarchy`:** This section recursively builds a hierarchy of movies based on the links between them. It fetches related movies and their depth in the relationship tree.

2. **CTE `DistinctKeywords`:** This fetches all distinct keywords for each movie, concatenating them into a single string.

3. **CTE `FinishedMovies`:** This focuses on gathering final details for each movie, including the title, production year, keywords, and counts of the related cast and companies.

4. **CTE `FinalReport`:** This combines information from the `FinishedMovies` and `MovieHierarchy` sections, preparing it for the final output.

5. **Final SELECT Statement:** Here, the results from `FinalReport` are selected with aggregations. It extracts the maximum link depth for each movie while filtering out those with no link depth.

The query combines multiple advanced SQL constructs, including CTEs, subqueries, outer joins, aggregation, and correlated conditions while showcasing SQL's capability to handle complex relationships and data analysis.
