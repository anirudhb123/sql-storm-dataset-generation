WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year IS NOT NULL AND 
        (mi.info_type_id IS NULL OR mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Tagline'))
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        movie_id, 
        title,
        cast_count,
        avg_order
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.cast_count,
    hcm.avg_order,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN hcm.cast_count > 10 THEN 'High Cast' 
        WHEN hcm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast' 
        ELSE 'Low Cast' 
    END AS cast_level
FROM 
    high_cast_movies hcm
LEFT JOIN 
    keyword_summary ks ON hcm.movie_id = ks.movie_id
ORDER BY 
    hcm.cast_count DESC, hcm.title;
