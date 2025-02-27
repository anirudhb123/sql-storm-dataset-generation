WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_member_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
        LEFT JOIN cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),

MovieCompaniesInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
        LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

MovieNotes AS (
    SELECT 
        m.id AS movie_id,
        m.note,
        CASE 
            WHEN m.note IS NULL OR TRIM(m.note) = '' THEN 'No notes available'
            ELSE m.note
        END AS processed_note
    FROM 
        aka_title m
),

FinalBenchmark AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_member_count,
        mci.production_companies,
        mci.distinct_company_types,
        mn.processed_note
    FROM 
        RankedMovies rm
        LEFT JOIN MovieCompaniesInfo mci ON rm.movie_id = mci.movie_id
        LEFT JOIN MovieNotes mn ON rm.movie_id = mn.movie_id
    WHERE 
        rm.year_rank <= 5  -- Top 5 movies per year
)

SELECT 
    *,
    CASE 
        WHEN cast_member_count > 10 THEN 'Large Ensemble'
        WHEN cast_member_count BETWEEN 6 AND 10 THEN 'Medium Ensemble'
        WHEN cast_member_count BETWEEN 1 AND 5 THEN 'Small Ensemble'
        ELSE 'No Cast' 
    END AS ensemble_size_category,
    COALESCE(mn.processed_note, 'No notes') AS final_note
FROM 
    FinalBenchmark
ORDER BY 
    production_year DESC, 
    cast_member_count DESC
LIMIT 20;
