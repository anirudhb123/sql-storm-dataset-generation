WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        COUNT(ci.id) OVER (PARTITION BY at.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year >= 2000
        AND at.production_year <= 2023
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', '), 'No companies') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.cast_count, mk.keywords
)
SELECT 
    cmi.*,
    (SELECT COUNT(DISTINCT person_id) 
     FROM cast_info ci
     WHERE ci.movie_id = cmi.movie_id) AS unique_cast_count,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = cmi.movie_id 
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')) AS plot_info_count
FROM 
    CompleteMovieInfo cmi
ORDER BY 
    cmi.cast_count DESC, 
    cmi.title ASC
LIMIT 10;

This SQL query does a performance benchmarking of top movies made from 2000 to 2023 based on their cast size and aggregates related information like keywords and production companies. It involves multiple CTEs, outer joins, string aggregations, and subqueries to extract relevant metrics for analysis. The final result set displays up to ten movies complete with cast count, associated keywords, and the unique cast count alongside additional info.
