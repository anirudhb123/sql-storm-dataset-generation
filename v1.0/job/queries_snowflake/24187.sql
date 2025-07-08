
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.season_nr, 0), 1) AS season_number,
        COALESCE(NULLIF(mt.episode_nr, 0), 1) AS episode_number
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.season_nr, 0), mh.season_number) AS season_number,
        COALESCE(NULLIF(mt.episode_nr, 0), mh.episode_number) AS episode_number
    FROM 
        aka_title mt
        JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.season_number,
    mh.episode_number,
    rc.name AS main_actor,
    NULLIF(mk.keywords, '') AS keywords,
    CASE 
        WHEN rc.role_rank IS NULL THEN 'No cast'
        WHEN rc.role_rank = 1 THEN 'Lead Actor'
        ELSE 'Supporting Actor'
    END AS actor_role,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rc ON mh.movie_id = rc.movie_id AND rc.role_rank <= 5
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year > 2000 
    AND (mh.title ILIKE '%the%' OR mh.title ILIKE '%an%')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, 
    mh.season_number, mh.episode_number, 
    rc.name, rc.role_rank, mk.keywords
ORDER BY 
    mh.production_year DESC, 
    CASE WHEN rc.role_rank IS NULL THEN 1 ELSE 0 END, 
    rc.role_rank
LIMIT 100;
