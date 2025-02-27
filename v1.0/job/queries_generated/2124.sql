WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT cm.company_id) AS production_companies
FROM 
    HighCastMovies hcm
LEFT JOIN 
    movie_companies cm ON hcm.title = (SELECT title FROM aka_title WHERE id = cm.movie_id)
LEFT JOIN 
    MovieKeywords mk ON hcm.production_year = (SELECT production_year FROM RankedMovies WHERE title = hcm.title)
GROUP BY 
    hcm.title, hcm.production_year, mk.keywords
ORDER BY 
    hcm.production_year DESC, production_companies DESC;
