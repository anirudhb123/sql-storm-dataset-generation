WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, LENGTH(t.title)) AS rnk
    FROM 
        aka_title t
)
, actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
)
, company_movie_summary AS (
    SELECT 
        mc.company_id,
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        ARRAY_AGG(DISTINCT t.title ORDER BY t.title) AS movie_titles
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.company_id, c.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 3
)
SELECT 
    r.title AS movie_title,
    r.production_year,
    a.movie_count AS total_actors,
    c.company_name,
    c.total_movies,
    CASE 
        WHEN c.total_movies > 10 THEN 'Established' 
        ELSE 'Emerging' 
    END AS company_status,
    STRING_AGG(DISTINCT a.rn::TEXT || ': ' || a.person_id ORDER BY a.rn) AS actors
FROM 
    ranked_movies r
LEFT JOIN 
    actor_movie_count a ON EXISTS (SELECT 1 FROM cast_info c WHERE c.movie_id = r.id AND c.person_id = a.person_id)
LEFT JOIN 
    company_movie_summary c ON c.total_movies >= 5
WHERE 
    r.rnk <= 3 OR r.production_year < 2000
GROUP BY 
    r.title, r.production_year, a.movie_count, c.company_name, c.total_movies
ORDER BY 
    r.production_year DESC, r.title;
