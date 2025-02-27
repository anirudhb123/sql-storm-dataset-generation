WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(CASE WHEN mt.info_type_id = 1 THEN 1 END) AS title_info_count,
        COUNT(CASE WHEN mt.info_type_id = 2 THEN 1 END) AS genre_info_count
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_info_idx mt ON mi.movie_id = mt.movie_id
    GROUP BY 
        mi.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(fc.title_info_count, 0) AS title_info_count,
        COALESCE(fc.genre_info_count, 0) AS genre_info_count,
        COALESCE(cc.company_count, 0) AS company_count,
        CASE
            WHEN COALESCE(fc.title_info_count, 0) > 0 THEN 'Information Available'
            ELSE 'Information Not Available'
        END AS info_status
    FROM 
        RankedTitles rt
    LEFT JOIN 
        FilteredMovieInfo fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        CompanyCounts cc ON rt.title_id = cc.movie_id
    WHERE 
        rt.year_rank <= 5 
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.title_info_count,
        tm.genre_info_count,
        tm.company_count,
        tm.info_status
    FROM 
        TopMovies tm
    WHERE 
        tm.production_year >= 2000 
)

SELECT 
    fo.title,
    fo.production_year,
    fo.title_info_count,
    fo.genre_info_count,
    fo.company_count,
    fo.info_status
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, 
    fo.title_info_count DESC
LIMIT 10;