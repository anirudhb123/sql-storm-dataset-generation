WITH RecursiveMovieStats AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.movie_id) AS cast_count,
        SUM(CASE WHEN cc.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
        SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS non_null_notes_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.movie_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt 
    LEFT JOIN 
        cast_info cc ON cc.movie_id = mt.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompaniesCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS companies_count,
        MAX(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rms.movie_id,
        rms.title,
        rms.production_year,
        rms.cast_count,
        rms.null_notes_count,
        rms.non_null_notes_count,
        ks.keywords_list,
        cc.companies_count,
        cc.main_company_type
    FROM 
        RecursiveMovieStats rms
    LEFT JOIN 
        KeywordStats ks ON rms.movie_id = ks.movie_id
    JOIN 
        CompaniesCount cc ON rms.movie_id = cc.movie_id
    WHERE 
        rms.rank_by_cast <= 5 AND rms.production_year BETWEEN 2000 AND 2023
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.null_notes_count,
    f.non_null_notes_count,
    CASE 
        WHEN f.companies_count > 3 THEN 'Diverse Companies' 
        WHEN f.companies_count NULL THEN 'No Companies'
        ELSE 'Limited Companies' 
    END AS company_type_description,
    COALESCE(f.keywords_list, 'No Keywords') AS keywords
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
