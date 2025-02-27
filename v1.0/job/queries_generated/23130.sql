WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY a.id) AS company_count,
        string_agg(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        mi.info,
        COUNT(*) OVER (PARTITION BY m.movie_id) AS info_count
    FROM 
        RankedMovies m
    JOIN 
        movie_info mi ON mi.movie_id = m.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_names,
        mi.info AS awards_info,
        rm.company_count,
        COALESCE(NULLIF(rm.production_year, 0), 'Unknown Year') AS display_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.company_count > 2 AND title_rank <= 3
)

SELECT 
    f.movie_id,
    f.title,
    f.display_year,
    f.cast_names,
    COALESCE(f.awards_info, 'No Awards Info') AS awards_info,
    CASE 
        WHEN f.company_count IS NULL THEN 'No Company Data'
        ELSE f.company_count || ' Companies' 
    END AS company_info
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC NULLS LAST, 
    f.title ASC;

-- Explanation:
-- 1. RankedMovies CTE ranks movies by title within their production year and counts distinct companies associated with each movie,
--    while aggregating the cast names.
-- 2. MovieInfo CTE retrieves awards-related information for each movie, counting the number of award-related entries.
-- 3. FilteredMovies CTE selects movies with more than two companies and only the top three titles per year, handling NULL production years elegantly.
-- 4. The main SELECT statement formats output to include fallback values for NULLs and constructs display strings for various fields, 
--    ensuring a comprehensive view of the data.
