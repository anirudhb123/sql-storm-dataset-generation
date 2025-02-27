WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_cast,
    COALESCE(cmc.company_count, 0) AS company_count,
    COALESCE(mii.info_details, 'No Info Available') AS info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCount cmc ON rm.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
LEFT JOIN 
    MovieInfo mii ON rm.production_year = (SELECT production_year FROM aka_title WHERE id = mii.movie_id LIMIT 1)
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast DESC;
