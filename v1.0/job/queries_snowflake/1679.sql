
WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
), 
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, '; ') AS aggregated_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
), 
TopMovies AS (
    SELECT 
        at.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.movie_id = c.movie_id
    JOIN 
        RankedTitles rt ON rt.title_id = at.id
    WHERE 
        rt.year_rank <= 5
    GROUP BY 
        at.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 2
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mi.aggregated_info, 'No Info Available') AS movie_details,
    tm.cast_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = rt.title_id
INNER JOIN 
    TopMovies tm ON tm.movie_id = rt.title_id
WHERE 
    rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.title;
