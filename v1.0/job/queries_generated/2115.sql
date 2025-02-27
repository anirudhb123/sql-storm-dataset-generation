WITH cast_movies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN ci.nr_order = 1 THEN a.name END) AS lead_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
ranked_movies AS (
    SELECT 
        md.title,
        md.production_year,
        md.production_companies,
        md.keyword_count,
        cm.total_cast,
        cm.lead_actor,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC, cm.total_cast DESC) AS rank
    FROM 
        movie_details md
    LEFT JOIN 
        cast_movies cm ON md.movie_id = cm.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.production_companies, 0) AS production_companies,
    COALESCE(rm.keyword_count, 0) AS keyword_count,
    rm.total_cast,
    rm.lead_actor
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year, rm.rank;
