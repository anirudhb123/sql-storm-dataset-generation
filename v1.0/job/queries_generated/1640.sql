WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.id
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_per_year
    FROM 
        movie_data
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        rank_per_year
    FROM 
        ranked_movies
    WHERE 
        rank_per_year <= 5
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cm.company_name, 'Independent') AS company_name,
    COALESCE(cm.company_type, 'N/A') AS company_type,
    tm.keywords,
    tm.cast_count
FROM 
    top_movies tm
LEFT JOIN 
    company_movies cm ON tm.movie_id = cm.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.rank_per_year;
