WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        COALESCE(k.keyword, 'Unknown') AS keyword,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorRoles AS (
    SELECT 
        ka.id AS actor_id,
        ka.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        COUNT(DISTINCT cs.id) AS appearance_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        complete_cast cs ON c.movie_id = cs.movie_id AND c.person_id = cs.subject_id
    WHERE 
        ka.name IS NOT NULL
    GROUP BY 
        ka.id, ka.name, c.movie_id, r.role
),
MovieStatistics AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ARRAY_AGG(DISTINCT ar.actor_name) AS all_actors,
        SUM(COALESCE(ar.appearance_count, 0)) AS total_appearances
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ar ON mh.movie_id = ar.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
)
SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.all_actors,
    ms.total_appearances,
    CASE 
        WHEN ms.total_appearances > 50 THEN 'Highly Featured'
        WHEN ms.total_appearances BETWEEN 20 AND 50 THEN 'Moderately Featured'
        ELSE 'Rarely Featured'
    END AS appearance_category,
    ARRAY_LENGTH(ms.all_actors, 1) AS actor_count,
    (SELECT COUNT(*) FROM aka_title WHERE production_year = ms.production_year) AS same_year_movie_count,
    (SELECT COALESCE(MAX(production_year), -1) FROM aka_title WHERE production_year < ms.production_year) AS last_year_before
FROM 
    MovieStatistics ms
WHERE 
    ms.production_year IS NOT NULL
    AND ms.production_year >= (SELECT MIN(production_year) FROM aka_title)
ORDER BY 
    ms.total_appearances DESC,
    ms.movie_title ASC
LIMIT 100;
