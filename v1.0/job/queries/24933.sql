WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ka.person_id,
        ka.name AS actor_name,
        row_number() OVER (PARTITION BY mt.id ORDER BY c.nr_order) AS actor_order,
        COALESCE(NULLIF(mt.kind_id, 0), -1) AS kind_id_modified
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    LEFT JOIN 
        aka_name ka ON ka.person_id = c.person_id
    WHERE 
        mt.production_year >= 2000
        AND (mt.note IS NULL OR mt.note NOT LIKE '%unreleased%')
),

actor_titles AS (
    SELECT
        md.movie_id,
        md.title,
        STRING_AGG(md.actor_name, ', ') AS actors_list,
        COUNT(*) AS actor_count,
        MAX(md.kind_id_modified) AS max_kind_id,
        COUNT(DISTINCT md.actor_order) FILTER (WHERE md.actor_order <= 5) AS top_five_actors,
        NULLIF(NULLIF(SUBSTRING(md.title, 1, 5), 'Demo'), '') AS title_extracted
    FROM 
        movie_data md
    GROUP BY 
        md.movie_id, md.title
),

highlighted_movies AS (
    SELECT
        at.movie_id,
        at.title,
        at.actors_list,
        at.actor_count,
        CASE 
            WHEN at.max_kind_id = 1 THEN 'Feature Film'
            WHEN at.max_kind_id = 2 THEN 'Documentary'
            ELSE 'Other'
        END AS category,
        CASE
            WHEN at.actor_count IS NULL THEN 'No Actors'
            WHEN at.actor_count < 3 THEN 'Fewer Actors'
            ELSE 'Many Actors'
        END AS actor_category
    FROM 
        actor_titles at
    WHERE 
        at.actor_count > 0
)

SELECT 
    hm.movie_id,
    hm.title,
    hm.actors_list,
    hm.actor_count,
    hm.category,
    hm.actor_category,
    (SELECT COUNT(*)
     FROM movie_link ml
     WHERE ml.movie_id = hm.movie_id) AS linked_movies_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM movie_companies mc 
     JOIN company_name cn ON mc.company_id = cn.id 
     WHERE mc.movie_id = hm.movie_id
    ) AS production_companies
FROM 
    highlighted_movies hm
WHERE 
    hm.actor_count > 0
ORDER BY 
    hm.actor_count DESC,
    hm.title
LIMIT 50;