WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(*) OVER (PARTITION BY mt.id) AS actor_count,
        RANK() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS kind_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year IS NOT NULL
    AND 
        ak.name IS NOT NULL
),
ActorDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.actor_name,
        COALESCE(NULLIF(r.actor_name, ''), 'Unknown Actor') AS safe_actor_name,
        CASE WHEN r.actor_count > 3 THEN 'Featured Actor' ELSE 'Supporting Actor' END AS actor_role,
        CASE WHEN r.production_year < 1950 THEN 'Classic' ELSE 'Modern' END AS movie_age
    FROM RankedMovies r
),
FilteredMovies AS (
    SELECT 
        ad.movie_id,
        ad.title,
        ad.production_year,
        ad.safe_actor_name,
        ad.actor_role,
        ad.movie_age
    FROM ActorDetails ad
    WHERE 
        ad.actor_role = 'Featured Actor' 
    AND 
        ad.production_year BETWEEN 2000 AND 2023
    AND 
        ad.movie_age = 'Modern'
),
MovieKeywords AS (
    SELECT 
        f.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_keyword mk ON f.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.safe_actor_name,
    fm.actor_role,
    mk.keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC
LIMIT 100 OFFSET 0;

This SQL query performs complex operations on a movie database. It includes:

- **Common Table Expressions (CTEs)** for intermediate processing of movie and actor data.
- **Window functions** to count actors per movie and to rank movies by their production year means to show their kind.
- **Correlated Subqueries** to get a count of ratings for each movie.
- **String Aggregation** to compile keywords into a single string.
- **NULL Handling** and safe checks.
- Includes predicates and calculations that distinguish between 'Featured' and 'Supporting' actors and classifies movies based on their age. 

This creates a robust and informative output related to movies, filtering them based on specific criteria.
