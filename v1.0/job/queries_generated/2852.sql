WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COALESCE(SUM(CASE WHEN c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%') THEN 1 ELSE 0 END), 0) AS lead_actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        r.title, 
        r.production_year, 
        r.lead_actor_count
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    CAST(NULLIF(tm.lead_actor_count, 0) AS INTEGER) AS lead_actors,
    (SELECT STRING_AGG(DISTINCT a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info ci ON ci.movie_id = tm.movie_id 
     WHERE ci.person_id = a.person_id) AS lead_actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year AND kind_id = tm.kind_id)
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
WHERE 
    cn.country_code IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.lead_actor_count DESC;
