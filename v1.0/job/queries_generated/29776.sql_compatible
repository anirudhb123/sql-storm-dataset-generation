
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Popular'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Less Known'
        END AS popularity_category
    FROM 
        ranked_movies rm
    WHERE 
        rm.production_year > 2000
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.popularity_category,
    f.cast_count,
    f.cast_names,
    f.keywords
FROM 
    filtered_movies f
WHERE 
    f.keywords LIKE '%action%'
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
