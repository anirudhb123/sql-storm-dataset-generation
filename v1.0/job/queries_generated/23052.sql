WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id = 1 -- Assuming 1 represents a relevant info_type
    WHERE 
        ct.kind IS NOT NULL
    GROUP BY 
        mc.movie_id
), 
KeywordRanking AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ci.company_names,
        ci.company_count,
        kr.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        KeywordRanking kr ON rm.movie_id = kr.movie_id
    WHERE 
        rm.rank_by_cast <= 10 OR rm.production_year > 2020 -- Focus on recent blockbusters or highly casted movies
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS cast_count,
    COALESCE(fm.company_names, 'No companies listed') AS company_names,
    COALESCE(fm.company_count, 0) AS company_count,
    COALESCE(fm.keywords, 'No keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    aka_name an ON fm.cast_count = (SELECT COUNT(DISTINCT person_id) FROM cast_info WHERE movie_id = fm.movie_id) AND an.person_id IS NOT NULL
WHERE 
    fm.production_year IS NOT NULL OR fm.cast_count > 0 -- Only include movies that have a year or cast
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC, 
    fm.title;
