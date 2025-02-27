WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mt.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_year
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        ak.person_id,
        ak.name,
        GROUP_CONCAT(DISTINCT rt.role ORDER BY rt.role) AS roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
),
final_output AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ar.name AS actor_name,
        ar.roles
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_roles ar ON rm.cast_count > 5 AND ar.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.cast_count,
    COALESCE(fo.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(fo.roles, 'No Roles Assigned') AS roles
FROM 
    final_output fo
WHERE 
    fo.rank_year <= 3
ORDER BY 
    fo.production_year DESC, fo.cast_count DESC;
