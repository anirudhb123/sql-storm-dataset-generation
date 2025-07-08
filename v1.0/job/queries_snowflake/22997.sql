
WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(COALESCE(t.production_year, 2000)) AS avg_production_year
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
company_movie_details AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS total_movies,
        LISTAGG(DISTINCT at.title, ', ') AS titles
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        aka_title at ON mc.movie_id = at.id
    WHERE 
        cn.country_code IN ('USA', 'UK')
    GROUP BY 
        cn.name
),
most_valuable_actors AS (
    SELECT 
        ai.actor_name,
        ai.movie_count,
        ai.avg_production_year,
        RANK() OVER (ORDER BY ai.movie_count DESC) AS actor_rank
    FROM 
        actor_info ai
    WHERE 
        ai.movie_count > 10 AND ai.avg_production_year < 2020
)
SELECT 
    r.year_rank,
    r.title,
    r.production_year,
    m.actor_name,
    cm.company_name,
    cm.total_movies,
    CASE 
        WHEN r.title LIKE '%(unreleased)%' THEN 'Pending Release'
        ELSE 'Released'
    END AS release_status
FROM 
    ranked_titles r
LEFT JOIN 
    most_valuable_actors m ON m.movie_count > 5
JOIN 
    company_movie_details cm ON ARRAY_CONTAINS(TO_ARRAY(cm.titles), m.actor_name)
WHERE 
    r.year_rank <= 5
ORDER BY 
    r.production_year DESC, 
    m.movie_count DESC NULLS LAST;
