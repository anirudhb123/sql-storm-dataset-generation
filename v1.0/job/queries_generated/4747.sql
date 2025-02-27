WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    GROUP BY 
        t.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.company_names, 'No companies') AS company_names,
    COALESCE(cd.company_types, 'No types') AS company_types,
    COALESCE(
        (SELECT 
            COUNT(*) 
         FROM 
            movie_keyword mk 
         WHERE 
            mk.movie_id = rm.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')), 
        0) AS action_keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank;
