WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        COUNT(ci.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title
),
company_movies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        cm.company_name,
        cm.company_type,
        rm.cast_count,
        rm.has_note,
        cm.keyword_count 
    FROM 
        ranked_movies rm
    LEFT JOIN 
        company_movies cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.year_rank <= 5 AND
        (cm.keyword_count > 0 OR cm.company_type IS NOT NULL)
)
SELECT 
    f.movie_title,
    f.company_name,
    f.company_type,
    f.cast_count,
    f.has_note,
    COALESCE(f.keyword_count, 0) AS keyword_count
FROM 
    filtered_movies f
ORDER BY 
    f.cast_count DESC, 
    f.movie_title ASC;
