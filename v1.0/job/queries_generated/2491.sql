WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
MoviesWithCast AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        cs.company_count,
        cs.company_names,
        COALESCE(COUNT(ci.person_id), 0) AS cast_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyStats cs ON r.movie_id = cs.movie_id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    GROUP BY 
        r.movie_id, r.title, r.production_year, cs.company_count, cs.company_names
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.company_count,
    mwc.company_names,
    mwc.cast_count,
    COALESCE(CASE 
        WHEN mwc.cast_count > 10 THEN 'Large Cast' 
        WHEN mwc.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Small Cast' END, 'Unknown') AS cast_size_category,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = mwc.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM 
    MoviesWithCast mwc
WHERE 
    mwc.production_year > 2000
ORDER BY 
    mwc.production_year DESC, mwc.title;
