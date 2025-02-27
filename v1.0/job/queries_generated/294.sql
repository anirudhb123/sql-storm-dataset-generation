WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
valid_companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(vc.company_count, 0) AS company_count,
        rm.cast_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        valid_companies vc ON rm.movie_id = vc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.company_count,
    md.cast_count + md.company_count AS total_involvement,
    CASE 
        WHEN md.company_count > 0 THEN 'Active Company Participation'
        ELSE 'No Company Participation'
    END AS company_status
FROM 
    movie_details md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, 
    total_involvement DESC;
