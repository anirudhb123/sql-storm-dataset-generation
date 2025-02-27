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
        m.id
),
CompanyGenres AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(ct.kind) AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cg.genres, 'Unknown') AS movie_genres,
    CASE 
        WHEN mi.movie_details IS NOT NULL THEN mi.movie_details 
        ELSE 'No details available' 
    END AS movie_details,
    COUNT(DISTINCT ca.person_id) AS total_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyGenres cg ON rm.movie_id = cg.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ca ON rm.movie_id = ca.movie_id
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cg.genres, mi.movie_details
ORDER BY 
    rm.production_year DESC, total_actors DESC;
