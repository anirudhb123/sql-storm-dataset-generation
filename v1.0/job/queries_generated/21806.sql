WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT m.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
),

AlphabeticalTitles AS (
    SELECT 
        DISTINCT title,
        ROW_NUMBER() OVER (ORDER BY title) AS alphabetical_rank
    FROM 
        RankedMovies
),

MovieInfo AS (
    SELECT 
        r.movie_id,
        COUNT(mi.info) AS info_count,
        STRING_AGG(mi.info, ', ') AS all_info
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_info mi ON r.movie_id = mi.movie_id
    GROUP BY 
        r.movie_id
),

FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        COALESCE(mi.all_info, 'No Info') AS all_info,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, m.cast_count DESC) AS rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieInfo mi ON m.movie_id = mi.movie_id
    WHERE 
        m.cast_count > 0 OR m.production_year IS NULL
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.all_info,
    COALESCE((
        SELECT 
            STRING_AGG(DISTINCT k.keyword, ', ')
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id = fm.movie_id
    ), 'No Keywords') AS keywords,
    at.alphabetical_rank,
    CASE 
        WHEN fm.production_year IS NOT NULL THEN 'Year Exists'
        ELSE 'Year Missing'
    END AS year_status
FROM 
    FilteredMovies fm
JOIN 
    AlphabeticalTitles at ON fm.title = at.title
WHERE 
    fm.rank <= 50
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;

