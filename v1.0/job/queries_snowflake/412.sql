
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        r.title, 
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword,
        CASE 
            WHEN k.keyword IS NULL THEN 'No Keyword'
            ELSE k.keyword 
        END AS keyword_display
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT a.id FROM aka_title a WHERE a.title = m.title AND a.production_year = m.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(MAX(ci.note), 'N/A') AS cast_notes,
        LISTAGG(DISTINCT mk.keyword_display, ', ') WITHIN GROUP (ORDER BY mk.keyword_display) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        MovieKeywords mk ON t.title = mk.title
    GROUP BY 
        t.title
)
SELECT 
    md.title,
    md.cast_notes,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.keywords IS NOT NULL
ORDER BY 
    md.title;
