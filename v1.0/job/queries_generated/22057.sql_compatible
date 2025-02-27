
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
filtered_cast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        c.note AS cast_note,
        COUNT(c.role_id) OVER (PARTITION BY c.movie_id) AS role_count,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.actor_name,
    fc.cast_note,
    fc.role_count,
    mk.keywords,
    ci.companies,
    COALESCE(fc.rank_order, 0) AS rank_order,
    CASE 
        WHEN fc.role_count > 10 THEN 'Large Cast'
        WHEN fc.role_count IS NULL THEN 'No Cast Info'
        ELSE 'Standard Cast'
    END AS cast_size_category
FROM 
    ranked_movies rm
LEFT JOIN 
    filtered_cast fc ON rm.movie_id = fc.movie_id AND fc.rank_order = 1
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank_year <= 5 
    AND (fc.cast_note IS NULL OR fc.cast_note <> '')
GROUP BY 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.actor_name,
    fc.cast_note,
    fc.role_count,
    mk.keywords,
    ci.companies,
    fc.rank_order
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
