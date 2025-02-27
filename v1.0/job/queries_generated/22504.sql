WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS cast_names,
        COUNT(*) AS num_cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id
), 
MovieAwards AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN m.info_type_id = 1 THEN m.info END) AS oscar_awards_won,
        COUNT(DISTINCT m.info) FILTER (WHERE m.info_type_id = 3) AS golden_globe_nominations
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(cd.num_cast_members, 0) AS num_cast_members,
    COALESCE(ma.oscar_awards_won, '0') AS oscar_awards,
    COALESCE(ma.golden_globe_nominations, 0) AS golden_globe_nominations,
    CASE 
        WHEN rm.rank_within_year <= 5 THEN 'Top 5 in Year'
        ELSE 'Not Top 5'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieAwards ma ON rm.movie_id = ma.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2023)
    AND (ma.oscar_awards_won IS NULL OR ma.oscar_awards_won < '2' OR ma.golden_globe_nominations IS NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;

### Explanation:
1. **CTEs**:
   - `RankedMovies`: Ranks movies by title within the same production year.
   - `CastDetails`: Collects names of cast members for each movie and counts them, grouping by movie ID.
   - `MovieAwards`: Aggregates awards won (like Oscars) and nominations for each movie.

2. **Main Query**:
   - Joins the three CTEs on `movie_id`.
   - Uses `COALESCE` to handle NULL values properly, providing default values like 'No Cast' and '0' for awards.
   - Applies a case statement to categorize the movie based on its rank within the year.

3. **Filtering & Ordering**:
   - Filters for movies produced between 2000 and 2023, ensuring certain conditions on awards are met.
   - Orders the final output by production year descending and title ascending.

This query exemplifies various SQL features, including CTEs, outer joins, aggregation with conditional counting, string concatenation, and complex filtering logic.
