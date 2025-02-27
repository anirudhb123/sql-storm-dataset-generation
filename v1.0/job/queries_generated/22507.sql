WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    GROUP BY 
        a.id,
        a.title,
        a.production_year
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
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No Info') AS info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_count,
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
    COALESCE(mi.info, 'No Additional Info') AS additional_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON fm.movie_id = mi.movie_id
WHERE
    fm.production_year IS NOT NULL
    AND fm.actor_count > 0
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;

-- The OUTPUT will list the top 5 movies with the highest actor counts per year,
-- along with their production year and aggregated keywords.
-- It demonstrates usage of CTEs, aggregations, string concatenation,
-- and the handling of NULL values, including obscured information
-- alongside bizarre semantic corner cases of info absence.
