WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        mt.production_year > 2000
),
company_associations AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
keyword_associations AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    ca.company_names,
    ka.keyword_count,
    md.actor_rank,
    CASE 
        WHEN ka.keyword_count IS NULL THEN 'No Keywords'
        WHEN ka.keyword_count > 5 THEN 'Rich in Keywords'
        ELSE 'Few Keywords'
    END AS keyword_status
FROM 
    movie_details md
LEFT JOIN 
    company_associations ca ON md.production_year = ca.movie_id
LEFT JOIN 
    keyword_associations ka ON md.production_year = ka.movie_id
WHERE 
    md.actor_rank <= 3
ORDER BY 
    md.production_year DESC, md.movie_title;
