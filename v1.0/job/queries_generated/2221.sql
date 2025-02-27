WITH movie_details AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS has_keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        a.title, a.production_year
),
high_cast_movies AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.total_cast,
        md.total_keywords,
        CAST(md.has_keywords AS boolean) AS has_keywords
    FROM 
        movie_details md
    WHERE 
        md.total_cast > 5
)
SELECT 
    hcm.title,
    hcm.production_year,
    COALESCE(NULLIF(hcm.total_keywords, 0), 'No Keywords') AS keyword_count,
    CASE 
        WHEN hcm.has_keywords THEN 'Contains Keywords' 
        ELSE 'No Keywords' 
    END AS keywords_status,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id IN (SELECT a.id FROM aka_title a WHERE a.title = hcm.title)) AS info_count
FROM 
    high_cast_movies hcm
ORDER BY 
    hcm.production_year DESC, 
    hcm.title;
