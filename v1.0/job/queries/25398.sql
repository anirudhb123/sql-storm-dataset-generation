WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS rank_order
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
distinct_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies,
        STRING_AGG(DISTINCT ckt.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ckt ON mc.company_type_id = ckt.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_order,
    rk.keyword_list,
    cd.companies,
    cd.company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    distinct_keywords rk ON rm.movie_id = rk.movie_id
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_order = 1
ORDER BY 
    rm.production_year DESC, rm.title;
