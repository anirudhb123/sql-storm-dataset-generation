WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order
    FROM 
        aka_title a
    JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
), 
movies_with_keywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword,
        COALESCE(COUNT(mk.id), 0) AS keyword_count
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year, k.keyword
),
final_results AS (
    SELECT 
        mw.title,
        mw.production_year,
        STRING_AGG(DISTINCT mw.keyword, ', ') AS keywords,
        MW.keyword_count
    FROM 
        movies_with_keywords mw
    GROUP BY 
        mw.title, mw.production_year
    HAVING 
        COUNT(mw.keyword) > 1
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords,
    CASE 
        WHEN fr.production_year < 2000 THEN 'Classic'
        WHEN fr.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS movie_era
FROM 
    final_results fr
ORDER BY 
    fr.production_year DESC, 
    fr.title;
