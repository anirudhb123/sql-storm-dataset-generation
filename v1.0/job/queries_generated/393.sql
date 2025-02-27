WITH ranked_titles AS (
    SELECT 
        a.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
complete_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        rk.rn,
        mk.keywords,
        cd.company_name,
        cd.company_type
    FROM 
        ranked_titles rk
    JOIN 
        aka_title t ON rk.title = t.title AND rk.production_year = t.production_year
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        company_details cd ON t.id = cd.movie_id
)
SELECT 
    ci.id AS cast_id,
    ci.person_id,
    ci.movie_id,
    ci.nr_order,
    ci.note,
    ci.role_id,
    ci.personal_role,
    ci.movie_role,
    ci.status_id,
    coalesce(ci.nr_order, 0) AS order_value,
    CASE
        WHEN ci.nr_order IS NULL THEN 'No Order'
        ELSE 'Ordered'
    END AS order_status,
    ci.movie_id IN (SELECT movie_id FROM complete_info WHERE rn = 1) AS is_latest_movie,
    ci.movie_id NOT IN (SELECT movie_id FROM complete_info WHERE company_name IS NULL) AS has_company_info
FROM 
    cast_info ci
JOIN 
    complete_info cinfo ON ci.movie_id = cinfo.title_id
WHERE 
    cinfo.keywords LIKE '%action%'
    OR cinfo.keywords IS NULL
ORDER BY 
    ci.nr_order DESC NULLS LAST;
