
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
company_summary AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies,
        LISTAGG(DISTINCT co.country_code, ', ') WITHIN GROUP (ORDER BY co.country_code) AS country_codes
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
cast_summary AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_details
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    cs.company_name,
    cs.company_type,
    cs.total_companies,
    cs.country_codes,
    CASE 
        WHEN css.total_cast IS NOT NULL THEN css.total_cast 
        ELSE 0 
    END AS total_cast_members,
    COALESCE(css.cast_details, 'No Cast Information') AS cast_details
FROM 
    ranked_movies rm
LEFT JOIN 
    company_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    cast_summary css ON rm.movie_id = css.movie_id
WHERE 
    (rm.rank_within_year <= 5 OR cs.total_companies > 2)
    AND (rm.production_year IS NOT NULL OR cs.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
