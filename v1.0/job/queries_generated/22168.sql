WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
        AND rm.actor_count > (SELECT AVG(actor_count) FROM RankedMovies)
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_count,
    COALESCE(mk.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN fm.actor_count IS NULL THEN 'Unknown'
        WHEN fm.actor_count >= 10 THEN 'Highly Casted'
        WHEN fm.actor_count BETWEEN 5 AND 9 THEN 'Moderately Casted'
        ELSE 'Lightly Casted'
    END AS casting_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_title = mk.movie_id
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;

### Explanation:
- **CTEs (Common Table Expressions)**:
  - `RankedMovies` computes the number of actors for each movie, assigns a rank based on actor count, and filters out movies without a production year.
  - `FilteredMovies` selects the top 5 movies for each production year with an actor count above the average.
  - `MovieKeywords` compiles all the keywords associated with each movie into a comma-separated string.

- **LEFT JOINs**:
  - Used to link relevant tables even when there are missing associations.

- **Aggregations**:
  - `COUNT(DISTINCT c.person_id)` and `STRING_AGG(DISTINCT k.keyword, ', ')` aggregate data at various levels.

- **NULL handling**:
  - `COALESCE` ensures that if there are no keywords, a default message is returned. 

- **CASE statements**: 
  - Provides an additional level of categorization based on actor counts, showcasing conditional logic.

- **Bizarre semantics**:
  - Usage of the STRING_AGG function with DISTINCT emphasizes unique keyword aggregation, which might not yield expected results for large datasets if not carefully considered, highlighting corner cases in aggregation behavior.
  
This elaborate query leverages many SQL features to provide insightful statistics and categorizations from the provided schema.
