WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        a.title, a.production_year
),
high_cast_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
)
SELECT 
    DISTINCT h.title,
    h.production_year,
    COALESCE(mc.company_name, 'Unknown Company') AS production_company,
    CASE 
        WHEN h.production_year < 2000 THEN 'Classic'
        WHEN h.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    high_cast_movies h
LEFT JOIN 
    movie_companies mc ON h.title = (SELECT title FROM aka_title WHERE id = mc.movie_id) 
LEFT JOIN 
    movie_keyword mk ON h.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    h.production_year IS NOT NULL
GROUP BY 
    h.title, h.production_year, mc.company_name
ORDER BY 
    h.production_year DESC, h.title;
