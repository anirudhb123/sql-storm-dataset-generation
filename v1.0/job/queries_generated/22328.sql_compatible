
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.production_year BETWEEN 2000 AND 2022
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),

movie_company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS num_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

detailed_movie_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cr.roles,
        cr.num_cast_members,
        mci.num_companies,
        mci.company_names,
        CASE 
            WHEN mci.num_companies < 1 THEN 'Independent'
            ELSE 'Studio'
        END AS production_type
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_roles cr ON rm.movie_id = cr.movie_id
    LEFT JOIN 
        movie_company_info mci ON rm.movie_id = mci.movie_id
)

SELECT 
    dmi.title,
    dmi.production_year,
    dmi.roles,
    dmi.num_cast_members,
    dmi.num_companies,
    dmi.company_names,
    dmi.production_type
FROM 
    detailed_movie_info dmi
WHERE 
    (dmi.num_cast_members IS NULL OR dmi.num_cast_members > 5)
  AND 
    (dmi.production_year IS NOT NULL AND dmi.production_year != 2015) 
ORDER BY 
    dmi.production_year DESC,
    dmi.num_cast_members DESC
LIMIT 50;
