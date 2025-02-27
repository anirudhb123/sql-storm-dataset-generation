WITH RankedMovies AS (
    SELECT 
        movie.id AS movie_id,
        movie.title AS movie_title,
        movie.production_year,
        COALESCE(SUM(CASE WHEN cast.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        RANK() OVER (PARTITION BY movie.id ORDER BY COUNT(DISTINCT cast.person_id) DESC) AS rank_by_cast
    FROM 
        title AS movie
    LEFT JOIN 
        complete_cast AS complete ON movie.id = complete.movie_id
    LEFT JOIN 
        cast_info AS cast ON complete.subject_id = cast.person_id
    GROUP BY 
        movie.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    mk.keywords,
    mc.companies,
    CASE 
        WHEN rm.cast_count > 5 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies AS mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.production_year IS NOT NULL
    AND rm.rank_by_cast <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 50;
