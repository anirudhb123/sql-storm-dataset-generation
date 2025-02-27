WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.kind_id) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
DirectorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        r.role LIKE 'Director%'
    GROUP BY 
        c.movie_id
), 
MoviesWithDirectorCounts AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.kind_id,
        COALESCE(dc.director_count, 0) AS director_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorCount dc ON rm.m_id = dc.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.kind_id,
    mw.director_count,
    CASE 
        WHEN mw.director_count IS NULL THEN 'No Director Info'
        WHEN mw.director_count = 0 THEN 'No Directors'
        WHEN mw.director_count > 1 THEN 'Multiple Directors'
        ELSE 'Single Director'
    END AS director_summary,
    string_agg(ka.name, ', ') AS aka_names
FROM 
    MoviesWithDirectorCounts mw
LEFT JOIN 
    aka_name ka ON ka.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mw.kind_id) 
GROUP BY 
    mw.title, mw.production_year, mw.kind_id, mw.director_count
HAVING 
    mw.production_year >= 2000 AND mw.director_count > 0
ORDER BY 
    mw.production_year DESC, 
    mw.title COLLATE "C" ASC
LIMIT 10
UNION ALL 
SELECT 
    NULL AS title,
    NULL AS production_year,
    NULL AS kind_id,
    COUNT(DISTINCT ci.person_id) AS director_count,
    'Total Directors' AS director_summary,
    NULL AS aka_names
FROM 
    cast_info ci
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    r.role LIKE 'Director%'
    AND ci.movie_id IS NOT NULL
ORDER BY 
    director_count;

### Explanation of the Query:
1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies`: Creates a ranking of movies by production year within each `kind_id`.
   - `DirectorCount`: Aggregates the number of distinct directors per movie based on a role filter.
   - `MoviesWithDirectorCounts`: Merges the two previous CTEs to associate movie titles with their director counts.

2. **Main Selection**: 
   - Selects movie title, year, kind ID, director count, and summarizes the number of directors into descriptive categories.
   - Uses `string_agg` to concatenate alternate names (aka names) of persons involved in the movie.

3. **Filtering and Grouping**:
   - Filters out movies produced before 2000 and those without at least one director.
   - Groups results to collate alternate names alongside basic movie details.

4. **Union**: 
   - The second part of the union selects the total count of directors across all movies.

5. **Ordering and Limiting**: 
   - Orders the results by production year and title, limiting the number of reported movies to 10.

This query incorporates a variety of concepts and constructs, showcasing a rich example of complex SQL with potential corner cases, such as handling NULL values and summarizing results.
