WITH movie_info_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords,
        STRING_AGG(c.name, ', ') AS companies,
        COUNT(DISTINCT a.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info a ON m.id = a.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
keyword_count AS (
    SELECT 
        keywords,
        COUNT(*) AS movie_count 
    FROM 
        movie_info_data
    GROUP BY 
        keywords
),
top_keywords AS (
    SELECT 
        keywords,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        keyword_count
    WHERE 
        movie_count >= 2
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.cast_count,
    COALESCE(t.movie_count, 0) AS occurrences,
    COALESCE(t.rank, 0) AS keyword_rank
FROM 
    movie_info_data m
LEFT JOIN 
    top_keywords t ON m.keywords = t.keywords
ORDER BY 
    m.production_year DESC, 
    occurrences DESC, 
    m.title;
