WITH recursive movie_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
), 
movie_details AS (
    SELECT 
        mt.title,
        mt.production_year,
        mk.keyword,
        ARRAY_AGG(DISTINCT mc.company_id) AS company_ids,
        ARRAY_AGG(DISTINCT mci.info) AS movie_info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_info mci ON mt.id = mci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year BETWEEN 2000 AND 2023
    GROUP BY mt.id
),
bizarre_actor AS (
    SELECT 
        mc.movie_id,
        max(CASE WHEN actor_rank = 1 THEN actor_name END) AS lead_actor,
        max(CASE WHEN actor_rank = 2 THEN actor_name END) AS second_actor,
        COUNT(DISTINCT actor_name) AS total_actors
    FROM 
        movie_cast mc
    WHERE 
        actor_rank <= 3
    GROUP BY mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    ba.lead_actor,
    ba.second_actor,
    COALESCE(ba.total_actors, 0) AS total_actors,
    (SELECT COUNT(*)
     FROM movie_link ml
     WHERE ml.movie_id = md.movie_id) AS total_links,
    (SELECT STRING_AGG(link_type.link, ', ')
     FROM movie_link ml
     JOIN link_type ON link_type.id = ml.link_type_id
     WHERE ml.movie_id = md.movie_id) AS link_types,
    CASE 
        WHEN md.production_year < 2010 THEN 'Pre-2010'
        WHEN md.production_year BETWEEN 2010 AND 2018 THEN '2010-2018'
        ELSE 'Post-2018'
    END AS production_period,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id = 1) THEN 'Has Info'
        ELSE 'No Info'
    END AS info_status
FROM 
    movie_details md
LEFT JOIN 
    bizarre_actor ba ON md.movie_id = ba.movie_id
WHERE 
    (md.keyword IS NOT NULL OR md.title ILIKE '%Sci-Fi%')
    AND NOT EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = md.title)
ORDER BY 
    md.production_year DESC, md.title;
