WITH RankedMovies AS (
    SELECT 
        a.title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    JOIN 
        title m ON a.movie_id = m.id
    GROUP BY 
        a.title, m.production_year
), 
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5  -- Top 5 movies per production year
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)

SELECT 
    tm.production_year, 
    tm.title, 
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Cast Exists'
    END AS cast_status
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id 
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
    
WITH RecursiveCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        1 AS level
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    UNION ALL
    SELECT 
        r.movie_id,
        cn.name,
        ct.kind,
        r.level + 1
    FROM 
        RecursiveCompanyInfo r
    JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        r.level < 3  -- Limit recursion to 3 levels
)
SELECT 
    movie_id,
    STRING_AGG(DISTINCT CONCAT(company_name, ' (', company_type, ')'), '; ') AS companies
FROM 
    RecursiveCompanyInfo
GROUP BY 
    movie_id
ORDER BY 
    movie_id;
