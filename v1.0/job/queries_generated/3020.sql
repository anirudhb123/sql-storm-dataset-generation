WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
), DirectorInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS directors
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mi.info_details, 'No Info') AS info_details,
    COALESCE(di.directors, 'No Directors') AS directors
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    DirectorInfo di ON rm.movie_id = di.movie_id
WHERE 
    rm.rank <= 5 AND (rm.cast_count > 0 OR di.directors IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
