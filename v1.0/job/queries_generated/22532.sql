WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rn <= 5
),
KeyMovieKeyword AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        k.keywords,
        COALESCE((
            SELECT 
                GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name)
            FROM 
                company_name cn
            JOIN 
                movie_companies mc ON mc.movie_id = tm.title_id AND mc.company_id = cn.id
            WHERE 
                mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
        ), 'No Production Company') AS production_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        KeyMovieKeyword k ON k.movie_id = tm.title_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    md.production_companies,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_period
FROM 
    MovieDetails md
WHERE 
    md.cast_count > 0
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;

-- Include corner case logic for NULLs in the keywords or production companies
WITH KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS kw_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
)
SELECT 
    md.title,
    COALESCE(md.keywords, 'No Keywords Available') AS keywords,
    COALESCE(kc.kw_count, 0) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON kc.movie_id = md.title_id
WHERE 
    keyword_count IS NOT NULL 
    OR md.keywords IS NOT NULL
ORDER BY 
    keyword_count DESC, md.title ASC;
