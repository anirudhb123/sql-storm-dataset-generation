WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

actor_role_counts AS (
    SELECT 
        ci.person_id, 
        COUNT(DISTINCT ci.role_id) AS role_count,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        ranked_movies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.person_id
),

unique_username AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        a.person_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.name) AS user_name_rank
    FROM 
        aka_name a
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    COALESCE(SUM(CASE WHEN ct.kind = 'Director' THEN 1 ELSE 0 END), 0) AS total_director_roles,
    COALESCE(STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword), 'No Keywords') AS keywords,
    COALESCE(x.rank, 0) AS latest_movie_rank,
    CASE 
        WHEN ar.role_count > 0 AND ar.movie_count = 0 THEN 'Standstill Actor' 
        WHEN ar.role_count = 0 THEN 'Unknown Actor' 
        ELSE 'Regular Actor'
    END AS actor_status
FROM 
    actor_role_counts ar
JOIN 
    unique_username u ON ar.person_id = u.person_id
LEFT JOIN 
    cast_info ci ON ci.person_id = ar.person_id
LEFT JOIN 
    ranked_movies x ON x.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    u.user_name_rank = 1
GROUP BY 
    a.name, ar.role_count, ar.movie_count, x.rank
HAVING 
    total_movies > 5 OR actor_status = 'Standstill Actor'
ORDER BY 
    total_movies DESC, latest_movie_rank ASC NULLS LAST;
