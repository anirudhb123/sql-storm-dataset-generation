WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rnk
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.person_id
),
company_movie_count AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movies_produced
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
),
featured_movie_info AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT i.info) AS movie_info
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        m.id
)
SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    r.production_year,
    r.title,
    COALESCE(cmc.movies_produced, 0) AS produced_by_company,
    COALESCE(amc.movie_count, 0) AS total_movies_acted,
    fmi.keywords,
    fmi.movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ca ON ak.person_id = ca.person_id
JOIN 
    ranked_titles r ON ca.movie_id = r.title_id
LEFT JOIN 
    actor_movie_count amc ON ak.person_id = amc.person_id
LEFT JOIN 
    movie_companies mc ON ca.movie_id = mc.movie_id
LEFT JOIN 
    company_movie_count cmc ON mc.company_id = cmc.company_id
LEFT JOIN 
    featured_movie_info fmi ON r.title_id = fmi.movie_id
WHERE 
    ak.name IS NOT NULL
AND 
    r.rnk = 1
ORDER BY 
    a.actor_id, r.production_year DESC;
