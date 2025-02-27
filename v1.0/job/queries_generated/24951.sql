WITH Recursive_Movie_Cte AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(
            (SELECT GROUP_CONCAT(a.name ORDER BY a.name) 
             FROM aka_title at 
             JOIN aka_name a ON at.id = a.id
             WHERE at.movie_id = mt.id),
            'No Known Aliases'
        ) AS aliases,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS movie_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
Filtered_Movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aliases 
    FROM 
        Recursive_Movie_Cte 
    WHERE 
        movie_rank <= 5
),
Cast_Role_Aggregation AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci 
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
Movies_With_Roles AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.aliases,
        coalesce(cr.num_actors, 0) as total_actors,
        coalesce(cr.roles, 'No Roles') as actor_roles
    FROM 
        Filtered_Movies fm
    LEFT JOIN 
        Cast_Role_Aggregation cr ON fm.movie_id = cr.movie_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.aliases,
    mw.total_actors,
    mw.actor_roles,
    CASE 
        WHEN mw.total_actors > 10 THEN 'Large Cast'
        WHEN mw.total_actors = 0 THEN 'No Cast'
        ELSE 'Moderate Cast'
    END AS cast_size,
    ROW_NUMBER() OVER (ORDER BY mw.production_year DESC, mw.title ASC) AS row_num
FROM 
    Movies_With_Roles mw
WHERE 
    mw.production_year > 2000
    AND EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = mw.movie_id 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Action', 'Drama'))
    )
ORDER BY 
    mw.production_year DESC,
    mw.aliases ASC
LIMIT 50;
