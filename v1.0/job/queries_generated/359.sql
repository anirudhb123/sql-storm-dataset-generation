WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.nr_order) AS cast,
        kt.keyword AS keyword
    FROM 
        aka_title t
    LEFT OUTER JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT OUTER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT OUTER JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, kt.keyword
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        cast,
        keyword,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS year_rank
    FROM 
        MovieDetails
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN keyword IS NULL THEN 'No Keywords' 
            ELSE keyword 
        END AS display_keyword
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast,
    fm.display_keyword,
    COALESCE(mi.info, 'No Info Available') AS movie_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.production_year = mi.movie_id AND mi.info_type_id = (
        SELECT 
            id FROM info_type WHERE info = 'Plot' LIMIT 1
    )
ORDER BY 
    fm.production_year DESC, fm.title;
