WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id
), 
interesting_actors AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL AND
        (a.name ILIKE '%Smith%' OR a.md5sum IS NULL)
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
), 
company_movie_counts AS (
    SELECT 
        mc.company_id, 
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        mc.company_id, ct.kind
)
SELECT 
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(rm.title, 'No Movie') AS movie_title,
    COALESCE(rm.production_year, 0) AS year,
    ca.movie_count AS actor_movie_count,
    cmt.total_movies AS company_movies,
    CASE 
        WHEN ca.movie_count > 10 THEN 'Prolific Actor'
        WHEN ca.movie_count BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Rare Actor'
    END AS actor_status,
    COUNT(DISTINCT km.keyword) AS keyword_count
FROM 
    interesting_actors ca
LEFT JOIN 
    ranked_movies rm ON ca.movie_count = rm.actor_rank
LEFT JOIN 
    movie_keyword km ON rm.movie_id = km.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_movie_counts cmt ON mc.company_id = cmt.company_id
WHERE 
    cmt.total_movies IS NULL OR cmt.total_movies > 5
GROUP BY 
    a.person_id, actor_name, movie_title, year, actor_movie_count, company_movies
ORDER BY 
    actor_status DESC, movie_title ASC;
