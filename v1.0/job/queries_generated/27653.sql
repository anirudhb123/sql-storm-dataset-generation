WITH ranked_titles AS (
    SELECT 
        at.title, 
        at.production_year,
        COUNT(cast.id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(cast.id) DESC) AS title_rank
    FROM 
        aka_title at
    JOIN 
        cast_info cast ON at.id = cast.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
recent_titles AS (
    SELECT 
        rt.title, 
        rt.production_year,
        rt.cast_count
    FROM 
        ranked_titles rt
    WHERE 
        rt.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
),

keyword_usage AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)

SELECT 
    rt.title, 
    rt.production_year,
    rt.cast_count,
    ku.keyword,
    ku.keyword_count
FROM 
    recent_titles rt
LEFT JOIN 
    keyword_usage ku ON rt.title = (SELECT title FROM aka_title WHERE id = rt.movie_id)
WHERE 
    rt.cast_count > 5
ORDER BY 
    rt.production_year DESC, 
    rt.cast_count DESC;
