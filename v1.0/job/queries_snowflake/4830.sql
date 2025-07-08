
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MoviesWithDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mk.keywords,
        (SELECT COUNT(*) 
         FROM movie_info mi 
         WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    COALESCE(mw.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mw.box_office_info IS NULL THEN 'No Box Office Data'
        ELSE CAST(mw.box_office_info AS TEXT)
    END AS box_office_info
FROM 
    MoviesWithDetails mw
ORDER BY 
    mw.production_year DESC, mw.title;
