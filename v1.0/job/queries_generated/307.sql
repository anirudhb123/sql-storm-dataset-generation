WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.name) AS total_companies,
        MAX(c.name) AS top_company
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'production')
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.cast_names,
    co.total_companies,
    co.top_company
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    company_summary co ON rm.movie_id = co.movie_id
WHERE 
    rm.rank_within_year <= 10
    AND (cs.total_cast IS NULL OR cs.total_cast > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
