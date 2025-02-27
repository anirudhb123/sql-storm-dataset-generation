WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
co_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(CASE WHEN ct.kind = 'Director' THEN ak.name END) AS director_name
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    GROUP BY 
        c.movie_id
),
company_info AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT co.name || ' (' || ct.kind || ')', '; ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),
unmatched_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        ranked_movies rm
    LEFT JOIN 
        co_cast cc ON rm.movie_id = cc.movie_id
    WHERE 
        cc.cast_count IS NULL
),
movie_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(cc.actors, 'No Cast') AS actors,
        COALESCE(company_info.companies, 'No Companies') AS companies,
        EXTRACT(YEAR FROM NOW()) - rm.production_year AS years_since_release
    FROM 
        ranked_movies rm
    LEFT JOIN 
        co_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        company_info ON rm.movie_id = company_info.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.actors,
    ms.companies,
    ms.years_since_release,
    CASE 
        WHEN ms.years_since_release > 20 THEN 'Classic'
        WHEN ms.years_since_release BETWEEN 10 AND 20 THEN 'Old'
        ELSE 'Recent'
    END AS age_category,
    CASE 
        WHEN ms.cast_count = 0 THEN 'Abandoned Project'
        WHEN ms.actors LIKE '%Unknown%' THEN 'Mysterious Film'
        ELSE 'Normal'
    END AS movie_note
FROM 
    movie_summary ms
WHERE 
    ms.years_since_release >= 0
ORDER BY 
    ms.production_year DESC, 
    ms.cast_count DESC
FETCH FIRST 100 ROWS ONLY;
