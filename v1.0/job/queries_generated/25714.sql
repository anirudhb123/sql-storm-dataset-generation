WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopKeywords AS (
    SELECT 
        keyword.keyword AS keyword,
        COUNT(mk.movie_id) AS count_per_keyword
    FROM 
        keyword 
    JOIN 
        movie_keyword mk ON keyword.id = mk.keyword_id
    GROUP BY 
        keyword.id, keyword.keyword
),
PopularTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        tk.keyword
    FROM 
        RankedTitles rt
    JOIN 
        TopKeywords tk ON rt.keyword_count > 0
    WHERE 
        rt.rank <= 10
)
SELECT 
    pt.title AS movie_title,
    pt.production_year,
    STRING_AGG(pt.keyword, ', ') AS associated_keywords
FROM 
    PopularTitles pt
GROUP BY 
    pt.title_id, pt.production_year
ORDER BY 
    pt.production_year DESC, 
    LENGTH(pt.title);

