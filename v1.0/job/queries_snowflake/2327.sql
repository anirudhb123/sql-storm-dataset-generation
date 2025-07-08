
WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_cast <= 5
),
company_movies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movies_with_company_info AS (
    SELECT 
        hcm.title_id,
        hcm.title,
        hcm.production_year,
        hcm.cast_count,
        COALESCE(cm.companies, 'No Companies') AS companies
    FROM 
        high_cast_movies hcm
    LEFT JOIN 
        company_movies cm ON hcm.title_id = cm.movie_id
)
SELECT 
    mwci.title,
    mwci.production_year,
    mwci.cast_count,
    mwci.companies
FROM 
    movies_with_company_info mwci
WHERE 
    mwci.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mwci.cast_count DESC,
    mwci.production_year ASC 
LIMIT 50;
