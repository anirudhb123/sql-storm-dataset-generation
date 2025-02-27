
WITH MovieRoleDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        rt.role AS role,
        COUNT(ci.id) AS total_appearances,
        t.id AS movie_id -- Added movie_id to GROUP BY and SELECT
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        t.title, t.production_year, ak.name, rt.role, t.id -- Added t.id
), KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    mrd.movie_title,
    mrd.production_year,
    mrd.actor_name,
    mrd.role,
    mrd.total_appearances,
    kc.total_keywords
FROM 
    MovieRoleDetails mrd
LEFT JOIN 
    KeywordCounts kc ON mrd.movie_id = kc.movie_id
WHERE 
    mrd.production_year >= 2000
ORDER BY 
    mrd.production_year DESC, 
    mrd.total_appearances DESC
LIMIT 50;
