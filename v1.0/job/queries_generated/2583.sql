WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Genre' THEN mi.info END, ', ') AS genres,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Director' THEN mi.info END, ', ') AS directors
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(cc.company_names, 'None') AS company_list,
    COALESCE(mi.genres, 'No Genre') AS genre_list,
    COALESCE(mi.directors, 'No Director') AS director_list
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5 AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, total_companies DESC;
