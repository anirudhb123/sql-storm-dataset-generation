WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(AVG(mr.rating), 0) AS average_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        LATERAL (SELECT 
                      CAST(mi.info AS NUMERIC) AS rating
                  FROM 
                      movie_info_idx mii
                  WHERE 
                      mii.movie_id = rm.movie_id) mr ON true
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.average_rating,
        cm.company_count
    FROM 
        TopRatedMovies tm
    LEFT JOIN 
        CompanyMovieCount cm ON tm.movie_id = cm.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.average_rating,
    COALESCE(fr.company_count, 0) AS company_count
FROM 
    FinalResults fr
WHERE 
    fr.average_rating > 7.5 
ORDER BY 
    fr.average_rating DESC, fr.production_year ASC;
