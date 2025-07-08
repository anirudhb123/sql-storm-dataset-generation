
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
)

SELECT 
    R.movie_id,
    R.title,
    R.production_year,
    COUNT(DISTINCT AR.actor_name) AS total_actors,
    COUNT(DISTINCT CASE WHEN AR.role_rank = 1 THEN AR.actor_name END) AS lead_actors,
    LISTAGG(DISTINCT AR.actor_name, ', ') WITHIN GROUP (ORDER BY AR.actor_name) AS all_actors,
    MAX(CASE WHEN R.keyword IS NULL THEN 'No Keyword' ELSE R.keyword END) AS movie_keyword
FROM 
    RankedMovies R
LEFT JOIN 
    ActorRoles AR ON R.movie_id = AR.movie_id
WHERE 
    (R.production_year BETWEEN 2000 AND 2020 OR R.production_year IS NULL)
GROUP BY 
    R.movie_id, R.title, R.production_year
HAVING 
    COUNT(DISTINCT AR.actor_name) > 5
    OR MAX(R.year_rank) IS NOT NULL
ORDER BY 
    R.production_year DESC, R.title;
