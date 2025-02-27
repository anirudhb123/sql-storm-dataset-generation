WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
), 
HighCastMovies AS (
    SELECT 
        title, 
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
), 
MovieKeywords AS (
    SELECT 
        m.title,
        array_agg(k.keyword) AS keywords
    FROM 
        HighCastMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    COALESCE(mk.keywords, '{}') AS keywords,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (
        SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = hcm.title)
    )) AS actor_count
FROM 
    HighCastMovies hcm
LEFT JOIN 
    MovieKeywords mk ON hcm.title = mk.title
WHERE 
    hcm.production_year >= 2000
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
