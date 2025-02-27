WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        c.id AS company_id,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS year_rank
    FROM
        aka_title mt
    LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
    JOIN company_name c ON c.id = mc.company_id
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND mt.production_year IS NOT NULL
),
ActorRankings AS (
    SELECT 
        ak.name AS actor_name,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_rank
    FROM
        aka_name ak
    JOIN cast_info c ON c.person_id = ak.person_id
    JOIN aka_title m ON m.id = c.movie_id 
    WHERE 
        ak.name IS NOT NULL
        AND c.nr_order IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN movie_keyword mk ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        k.keyword_count
    FROM 
        RecursiveMovieCTE m
    JOIN MovieKeywords k ON m.movie_id = k.movie_id
    WHERE 
        k.keyword_count > 2
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    coalesce(ar.actor_name, 'Unknown Actor') AS lead_actor,
    fm.keyword_count,
    COALESCE(cn.country_code, 'N/A') AS country_code,
    COUNT(DISTINCT mc.company_id) AS company_count,
    MAX(mk.keyword_count) OVER () AS highest_keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN ActorRankings ar ON fm.movie_id = ar.movie_id AND ar.actor_rank = 1
LEFT JOIN movie_companies mc ON mc.movie_id = fm.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
GROUP BY 
    fm.movie_id, ar.actor_name, fm.production_year, fm.title, cn.country_code
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    fm.production_year DESC, fm.title ASC;

### Explanation:
1. **CTEs**:
    - `RecursiveMovieCTE`: Collects movie details, focusing on those with production years, using a LEFT JOIN to include all relevant movie companies.
    - `ActorRankings`: Determines the lead actor for each movie using `RANK()`, accounting for their order.
    - `MovieKeywords`: Counts keywords associated with each movie.

2. **FilteredMovies**: Uses previously defined CTEs to filter movies that have more than 2 keywords.

3. **Main Query**: 
    - Combines data from `FilteredMovies`, `ActorRankings`, and `movie_companies`.
    - Calculates total companies associated with each movie and handles NULL logic utilizing `COALESCE`.
    - Groups results and employs the `HAVING` clause to only show movies produced by more than one company.
    
4. **Window function** (`MAX()`): Captures the maximum keyword count over the output set to identify the movie with the most keywords.

5. **ORDER BY**: Sorts results by production year (descending) and title (ascending). 

This SQL query provides a comprehensive approach to analyzing movie data while incorporating various SQL constructs and conditions.
