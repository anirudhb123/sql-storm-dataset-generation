WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
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
        m.title,
        k.keyword,
        mp.id AS movie_id
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mp ON m.title = (SELECT title FROM aka_title WHERE id = mp.movie_id)
    JOIN 
        keyword k ON mp.keyword_id = k.id
)
SELECT 
    mk.title,
    mk.keyword,
    CASE 
        WHEN mk.title IS NOT NULL THEN 'Keyword Found'
        ELSE 'No Keyword'
    END AS keyword_status,
    COALESCE(k.keyword, 'Unknown') AS keyword_detail
FROM 
    MovieKeywords mk
FULL OUTER JOIN 
    keyword k ON mk.keyword = k.keyword
WHERE 
    (mk.title IS NOT NULL OR k.keyword IS NOT NULL)
ORDER BY 
    mk.production_year DESC, mk.title;
