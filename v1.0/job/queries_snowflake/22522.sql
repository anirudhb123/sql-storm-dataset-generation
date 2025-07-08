
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCredits AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.person_id) AS cast_count,
        SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS missing_order_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), MovieAnalysis AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        mc.cast_count,
        mc.missing_order_count,
        mcd.company_count,
        mcd.company_names,
        rm.keyword_count,
        CASE 
            WHEN rm.keyword_count > 10 THEN 'Highly Tagged'
            WHEN rm.keyword_count > 5 THEN 'Moderately Tagged'
            ELSE 'Sparsely Tagged'
        END AS Tag_Status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCredits mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
)
SELECT 
    ma.title,
    ma.production_year,
    ma.cast_count,
    ma.missing_order_count,
    COALESCE(ma.company_count, 0) AS company_count,
    ma.company_names,
    ma.keyword_count,
    ma.Tag_Status,
    CASE 
        WHEN ma.cast_count IS NULL AND ma.company_count IS NULL THEN 'Unreleased'
        WHEN ma.cast_count = 0 THEN 'No Cast'
        ELSE 'Released'
    END AS Release_Status
FROM 
    MovieAnalysis ma
WHERE 
    ma.year_rank <= 5
ORDER BY 
    ma.production_year DESC, ma.keyword_count DESC;
