
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopRankedMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.ranking <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id AS title_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    JOIN 
        TopRankedMovies tr ON m.movie_id = tr.title_id
    GROUP BY 
        m.movie_id
)
SELECT 
    tr.title_id,
    tr.title,
    tr.production_year,
    tr.cast_count,
    mk.keywords
FROM 
    TopRankedMovies tr
LEFT JOIN 
    MovieKeywords mk ON tr.title_id = mk.title_id
ORDER BY 
    tr.production_year DESC, 
    tr.cast_count DESC;
