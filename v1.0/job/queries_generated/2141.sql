WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(mci.movie_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mci.movie_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    GROUP BY 
        mt.title, mt.production_year
), MovieDetails AS (
    SELECT 
        m.title, 
        m.production_year,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        COALESCE(SUM(mk.keyword IS NOT NULL)::int, 0) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.title = cc.subject_id
    LEFT JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    WHERE 
        m.rank <= 5
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keyword_count,
    CASE 
        WHEN md.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    MovieDetails md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;
