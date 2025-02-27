
WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ka.name, 'Unknown') AS actor_name,
        ka.person_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ka.name) AS actor_rank,
        COUNT(DISTINCT kc.keyword) AS total_keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ka ON c.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year > 2000
        AND (ka.name IS NOT NULL OR c.note IS NOT NULL)
    GROUP BY 
        t.id, t.title, t.production_year, ka.name, ka.person_id
),
DetailedInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_name,
        md.actor_rank,
        md.total_keywords,
        CASE 
            WHEN md.total_keywords > 5 THEN 'High'
            WHEN md.total_keywords BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS keyword_quality,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_keywords DESC) AS year_rank
    FROM 
        MovieData AS md
)
SELECT 
    di.title,
    di.production_year,
    di.actor_name,
    di.keyword_quality,
    COALESCE(cn.name, 'No Company') AS company_name,
    COUNT(mc.movie_id) AS company_count,
    SUM(CASE WHEN di.actor_rank = 1 THEN 1 ELSE 0 END) AS leading_role_count,
    CASE 
        WHEN di.actor_name IS NULL THEN 'Actor data missing' 
        ELSE 'Actor data available' 
    END AS actor_status
FROM 
    DetailedInfo AS di
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = di.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
WHERE 
    di.year_rank <= 5 
GROUP BY 
    di.title, di.production_year, di.actor_name, di.keyword_quality, cn.name
ORDER BY 
    di.production_year DESC, company_count DESC
LIMIT 10;
