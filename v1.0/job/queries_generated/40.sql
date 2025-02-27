WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.company_id::text, ', ') AS production_companies,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
), actor_details AS (
    SELECT 
        a.person_id,
        a.name,
        aa.movie_id,
        COUNT(DISTINCT aa.role_id) OVER (PARTITION BY a.person_id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info aa ON a.person_id = aa.person_id
), ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY md.keyword_count DESC) AS rank_by_keywords
    FROM 
        movie_details md
)
SELECT 
    rm.title,
    rm.production_year,
    rm.production_companies,
    ad.name AS actor_name,
    ad.role_count
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.movie_id = ad.movie_id
WHERE 
    rm.production_year IS NOT NULL
AND 
    (ad.role_count IS NULL OR ad.role_count > 2)
ORDER BY 
    rm.rank_by_keywords ASC, 
    ad.role_count DESC;
