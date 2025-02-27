
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS rank_by_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        total_cast,
        ordered_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL AND cn.country_code <> ''
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.total_cast,
    tm.ordered_cast,
    COALESCE(mk.all_keywords, 'No Keywords') AS keywords,
    COALESCE(cc.total_companies, 0) AS company_count,
    CASE 
        WHEN tm.ordered_cast = tm.total_cast THEN 'All Cast Ordered'
        ELSE 'Incomplete Ordering'
    END AS cast_order_status,
    CASE 
        WHEN cc.total_companies > 0 THEN 'Companies Exist'
        ELSE 'No Companies Listed'
    END AS company_status
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyCount cc ON tm.movie_id = cc.movie_id
WHERE 
    (tm.total_cast IS NOT NULL AND tm.total_cast > 0)
    OR (cc.total_companies IS NOT NULL AND cc.total_companies > 0)
ORDER BY 
    tm.title ASC
LIMIT 50;
