WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS movie_count
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(c.movie_id) AS total_movies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
    GROUP BY 
        a.id, a.name
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.actor_name,
        ai.total_movies,
        cd.company_names,
        rm.movie_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ai.actor_id)
    LEFT JOIN 
        company_details cd ON rm.movie_id = cd.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    COALESCE(ms.actor_name, 'Unknown Actor') AS actor_name,
    ms.total_movies,
    ms.company_names,
    CASE 
        WHEN ms.movie_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    movie_summary ms
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, 
    ms.title;
