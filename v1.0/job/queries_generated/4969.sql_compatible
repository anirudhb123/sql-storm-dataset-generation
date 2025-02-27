
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        tt.title,
        tt.production_year,
        COALESCE(tk.keywords, 'No Keywords') AS keywords,
        COUNT(ci.id) AS cast_count
    FROM 
        TopTitles tt
    LEFT JOIN 
        aka_title at ON tt.title_id = at.movie_id
    LEFT JOIN 
        complete_cast cc ON at.movie_id = cc.movie_id
    LEFT JOIN 
        TitleKeywords tk ON at.movie_id = tk.movie_id
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        tt.title, tt.production_year, tk.keywords
)
SELECT 
    cmi.title,
    cmi.production_year,
    cmi.keywords,
    cmi.cast_count
FROM 
    CompleteMovieInfo cmi
WHERE 
    cmi.cast_count > 0
ORDER BY 
    cmi.production_year DESC, 
    cmi.title;
