
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
), 
company_details AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type
FROM 
    filtered_movies f
LEFT JOIN 
    company_details cd ON f.title = (
        SELECT t.title 
        FROM aka_title t 
        WHERE t.id = (
            SELECT mc.movie_id 
            FROM movie_companies mc 
            WHERE mc.movie_id IN (
                SELECT movie_id 
                FROM complete_cast cc 
                WHERE cc.subject_id = f.production_year
            ) 
            LIMIT 1
        )
    )
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 10;
