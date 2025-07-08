
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cd.companies, 'No Companies') AS company_names,
    COALESCE(kw.keyword_list, 'No Keywords') AS keyword_summary,
    CASE 
        WHEN rm.rank_per_year <= 3 THEN 'Top 3 Of Year'
        ELSE 'Other'
    END AS movie_ranking
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_counts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    keywords kw ON rm.movie_id = kw.movie_id
WHERE 
    rm.production_year >= 2000
    AND (rm.title ILIKE '%action%' OR rm.title ILIKE '%drama%')
ORDER BY 
    rm.production_year DESC, 
    movie_ranking, 
    rm.title ASC;
