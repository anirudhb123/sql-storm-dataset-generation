WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank_by_keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopKeywords AS (
    SELECT 
        mk.keyword AS keyword,
        COUNT(mk.keyword_id) AS occurences
    FROM 
        movie_keyword mk
    JOIN 
        aka_title t ON mk.movie_id = t.id
    GROUP BY 
        mk.keyword
    ORDER BY 
        occurences DESC
    LIMIT 5
),
TopTitles AS (
    SELECT 
        rt.title_id, 
        rt.movie_title, 
        rt.production_year,
        rt.keyword_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_by_keywords <= 3
)
SELECT 
    tt.movie_title,
    tt.production_year,
    tt.keyword_count,
    STRING_AGG(tk.keyword, ', ') AS top_keywords
FROM 
    TopTitles tt
JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
JOIN 
    TopKeywords tk ON mk.keyword_id = tk.keyword_id
GROUP BY 
    tt.movie_title, 
    tt.production_year,
    tt.keyword_count
ORDER BY 
    tt.production_year DESC, 
    tt.keyword_count DESC;
