WITH Recursive_Actor_Roles AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY ct.kind) AS role_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
Movie_Details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT ka.name), 'No Actors') AS actors,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    GROUP BY 
        mt.id
),
Filtered_Movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.actor_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS movies_rank
    FROM 
        Movie_Details md
    WHERE 
        md.actor_count > 2
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actors,
    COALESCE((SELECT COUNT(DISTINCT mk.id) FROM movie_keyword mk WHERE mk.movie_id = fm.movie_id), 0) AS keyword_count,
    COALESCE(NULLIF((SELECT COUNT(DISTINCT mc.company_id) 
                    FROM movie_companies mc 
                    WHERE mc.movie_id = fm.movie_id AND mc.note IS NOT NULL), 0), 'No Companies') AS company_count
FROM 
    Filtered_Movies fm
WHERE 
    fm.movies_rank <= 5
ORDER BY 
    fm.production_year DESC,
    fm.actor_count DESC;
