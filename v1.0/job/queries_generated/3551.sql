WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
),
company_details AS (
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
    WHERE 
        cn.name IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(c.rc, 0) AS total_roles,
    COALESCE(mi.movie_info, 'No additional info') AS additional_info,
    cd.company_name,
    cd.company_type
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_role_counts c ON rm.movie_id = c.movie_id
LEFT JOIN 
    movie_info_filtered mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
WHERE 
    (rm.rank <= 10 OR cd.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.title;
