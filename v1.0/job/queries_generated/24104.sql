WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year IS NOT NULL
),

cast_details AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        r.role,
        COALESCE(SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END), 0) OVER (PARTITION BY c.movie_id ORDER BY r.role) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),

movie_company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),

titles_with_keyword AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, k.keyword
),

final_benchmark AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        cd.role_count,
        COALESCE(mci.company_count, 0) AS company_count,
        COALESCE(twk.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN cd.role_count > 10 THEN 'High' 
            WHEN cd.role_count BETWEEN 5 AND 10 THEN 'Medium' 
            ELSE 'Low' 
        END AS role_level
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_details cd ON r.title_id = cd.movie_id
    LEFT JOIN 
        movie_company_info mci ON r.title_id = mci.movie_id
    LEFT JOIN 
        titles_with_keyword twk ON r.title_id = twk.movie_id
)

SELECT 
    *
FROM 
    final_benchmark
WHERE 
    production_year > 2000 
    AND (role_count IS NULL OR role_count < 5)
ORDER BY 
    production_year DESC, 
    title;
