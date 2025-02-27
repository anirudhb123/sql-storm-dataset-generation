WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
),
MovieKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN m.production_year >= 2000 THEN 'Modern Era'
        WHEN m.production_year >= 1980 THEN 'Classic Era'
        ELSE 'Old School'
    END AS era,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id AND ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead')) AS lead_roles
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords k ON m.title = k.title
ORDER BY 
    m.production_year DESC;
