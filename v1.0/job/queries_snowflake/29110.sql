
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank
    FROM 
        title m
),
movie_keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
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
    rm.kind_id,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.company_names, 'No companies') AS company_names,
    COALESCE(ci.company_types, 'No types') AS company_types,
    COUNT(cc.person_id) AS cast_count
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keyword_summary mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    cast_info cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.rank <= 3
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.kind_id, mk.keyword_count, mk.keywords, ci.company_names, ci.company_types
ORDER BY 
    rm.production_year DESC, rm.movie_id;
