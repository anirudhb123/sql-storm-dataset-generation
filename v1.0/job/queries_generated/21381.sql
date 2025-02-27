WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.title) AS title_count
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS distinct_roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name, c.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info IS NOT NULL
    WHERE 
        m.production_year >= 2000
),
performance_benchmark AS (
    SELECT 
        a.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        mt.keyword,
        mt.movie_info,
        at.year_rank,
        at.title_count,
        a.distinct_roles,
        COUNT(DISTINCT c.movie_id) OVER (PARTITION BY a.id) AS total_movies,
        CASE 
            WHEN a.distinct_roles = 0 THEN 'No Roles'
            WHEN a.distinct_roles > 5 THEN 'Veteran'
            ELSE 'Novice'
        END AS actor_experience
    FROM 
        actor_info a
    JOIN 
        movie_details mt ON a.movie_id = mt.movie_id
    JOIN 
        ranked_titles at ON mt.title = at.title AND mt.production_year = at.production_year
)
SELECT 
    pb.actor_name,
    COUNT(*) AS total_performance_records,
    SUM(pb.distinct_roles) AS total_roles,
    AVG(pb.title_count) AS avg_title_count,
    LISTAGG(pb.keyword, ', ') AS keywords_collected
FROM 
    performance_benchmark pb
WHERE 
    pb.year_rank <= 5
GROUP BY 
    pb.actor_name
HAVING 
    total_roles > 10
ORDER BY 
    avg_title_count DESC, total_performance_records ASC
LIMIT 10;

