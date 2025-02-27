WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN r.role LIKE 'lead%' THEN 1 ELSE 0 END) AS lead_role_percentage
    FROM 
        aka_title AS m
    JOIN 
        cast_info AS c ON m.id = c.movie_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        m.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.lead_role_percentage,
        mk.keywords
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        MovieKeywords AS mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.lead_role_percentage,
    md.keywords,
    COUNT(DISTINCT ci.person_id) AS unique_cast_members
FROM 
    MovieDetails AS md
LEFT JOIN 
    cast_info AS ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_cast, md.lead_role_percentage, md.keywords
ORDER BY 
    md.production_year DESC, md.total_cast DESC;

This SQL query performs the following operations:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Aggregates movie data, counting unique cast members and calculating the percentage of lead roles.
   - `MovieKeywords`: Retrieves all keywords associated with each movie, concatenated into a single string.
   - `MovieDetails`: Combines results from `RankedMovies` and `MovieKeywords`.

2. **Final Selection**: Selects relevant information from the combined CTEs while counting distinct cast members again in the final output.

3. **Ordering**: Sorts the final results by production year and total cast count in descending order. 

This query provides a comprehensive view of movie statistics, including total cast, lead role percentages, and keywords for benchmarking string processing.
