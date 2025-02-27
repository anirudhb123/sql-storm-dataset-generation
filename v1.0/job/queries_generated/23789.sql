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
    STRING_AGG(DISTINCT AR.actor_name, ', ') AS all_actors,
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

WITH FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mk.keyword, 'No Tags') AS movie_tags
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL
)

SELECT 
    FM.movie_id,
    FM.movie_tags,
    COUNT(DISTINCT c.person_id) AS distinct_cast_count,
    MAX(CASE WHEN COALESCE(ct.kind, 'Unknown') = 'Production' THEN 1 ELSE 0 END) AS has_production_company
FROM 
    FilteredMovies FM
LEFT JOIN 
    movie_companies mc ON FM.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    cast_info c ON FM.movie_id = c.movie_id
GROUP BY 
    FM.movie_id, FM.movie_tags
HAVING 
    COUNT(DISTINCT c.person_id) > 10
    AND SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) = 0
ORDER BY 
    distinct_cast_count DESC
LIMIT 50 OFFSET 0;
