WITH 
    MovieRatings AS (
        SELECT 
            m.id AS movie_id,
            COALESCE(AVG(r.rating), 0) AS avg_rating
        FROM 
            aka_title m
        LEFT JOIN 
            ratings r ON m.id = r.movie_id
        GROUP BY 
            m.id
    ),
    CastRoles AS (
        SELECT
            c.movie_id,
            COUNT(DISTINCT c.person_id) AS distinct_cast_count,
            STRING_AGG(DISTINCT p.name, ', ') AS cast_names
        FROM 
            cast_info c
        JOIN 
            aka_name p ON c.person_id = p.person_id
        GROUP BY 
            c.movie_id
    ),
    MovieWithDetails AS (
        SELECT 
            m.id AS movie_id,
            m.title,
            m.production_year,
            COALESCE(mr.avg_rating, -1) AS avg_rating,
            COALESCE(cr.distinct_cast_count, 0) AS distinct_cast_count,
            COALESCE(cr.cast_names, 'No Cast') AS cast_names
        FROM 
            aka_title m
        LEFT JOIN 
            MovieRatings mr ON m.id = mr.movie_id
        LEFT JOIN 
            CastRoles cr ON m.id = cr.movie_id
        WHERE 
            m.production_year IS NOT NULL
            AND m.title IS NOT NULL
    ),
    FilteredMovies AS (
        SELECT 
            *,
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY avg_rating DESC NULLS LAST) AS ranking
        FROM 
            MovieWithDetails
        WHERE 
            distinct_cast_count > 0
    )
SELECT 
    f.title,
    f.production_year,
    f.avg_rating,
    f.cast_names 
FROM 
    FilteredMovies f
WHERE 
    f.ranking <= 5
ORDER BY 
    f.production_year DESC, 
    f.avg_rating DESC;

This query constructs a detailed ranking of movies by year while aggregating specific data related to average ratings and cast members. Here's the breakdown of the components:

1. **Common Table Expressions (CTEs)**:
   - `MovieRatings`: Computes average ratings for each movie, defaulting to 0 if no ratings are found using `COALESCE`.
   - `CastRoles`: Aggregates information on cast members per movie, including the count of distinct actors and a concatenated string of names.
   - `MovieWithDetails`: Joins the previous CTEs with the main `aka_title` to compile comprehensive details, filtering out movies without a production year or title.

2. **Window Function**:
   - `ROW_NUMBER()` assigns a ranking to each movie within its production year based on average ratings, ensuring that ties are handled with nulls last in the ordering.

3. **Final Selection**:
   - Filters for the top 5 movies per year that have a cast count greater than 0 and orders those results by year and rating.

This query includes NULL handling and more complex SQL features to benchmark performance in relation to join strategies, aggregation, and ordering.
