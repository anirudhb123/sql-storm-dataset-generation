WITH RankedMovies AS (
    SELECT 
        tit.id AS movie_id,
        tit.title,
        tit.production_year,
        ROW_NUMBER() OVER (PARTITION BY tit.production_year ORDER BY tit.production_year DESC, tit.title) as rank
    FROM 
        aka_title tit
    WHERE 
        tit.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieDetails AS (
    SELECT 
        mv.movie_id,
        mv.title,
        COALESCE(NULLIF(mn.name, ''), 'Unknown') AS movie_name,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies mv
    LEFT JOIN 
        movie_keyword mk ON mv.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mv.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name mn ON ci.person_id = mn.person_id
    GROUP BY 
        mv.movie_id, mv.title
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.actor_count,
        m.keywords,
        mi.info AS additional_info
    FROM 
        MovieDetails m
    LEFT JOIN
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.actor_count,
    mi.keywords,
    COALESCE(mi.additional_info, 'No additional information available') AS additional_info,
    CASE 
        WHEN mi.actor_count IS NULL THEN 'No actors found'
        WHEN mi.actor_count = 0 THEN 'No actors listed'
        ELSE 'Actors present'
    END AS actor_status
FROM 
    MovieInfo mi
WHERE 
    mi.actor_count IS NOT NULL
    OR mi.keywords IS NOT NULL
ORDER BY 
    mi.title ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

### Explanation:
- The query employs several advanced SQL constructs:
  - **Common Table Expressions (CTEs)** are used to create a temporary result set for ranked movies, top movies, and to gather movie details.
  - **Window functions** like `ROW_NUMBER()` rank movies by their production year and title within the `RankedMovies` CTE.
  - **LEFT JOINs** are used for nullable fields ensuring that we maintain the left data even when corresponding records don’t exist.
  - **COALESCE** and **NULLIF** functions are utilized to provide fallback values and handle NULL entries gracefully.
  - The use of **STRING_AGG** helps in aggregating keywords into a comma-separated list.
  - The query finalizes the data selection with conditional logic using a `CASE` statement to determine the status of the actors.
- The final select is also limited to provide pagination, fetching the top 10 records based on specified criteria.
