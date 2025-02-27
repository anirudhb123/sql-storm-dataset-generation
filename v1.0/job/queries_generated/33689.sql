WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- Assuming '1' relates to a movie type, for example
 
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        ci.note,
        COALESCE(comp.kind, 'Other') AS company_type
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_type comp ON mc.company_type_id = comp.id
),

movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        MAX(rc.actor_name) AS lead_actor,
        COUNT(rc.actor_name) AS total_cast,
        MAX(rc.company_type) AS production_company
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast rc ON mh.movie_id = rc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    md.title,
    md.production_year,
    md.lead_actor,
    md.total_cast,
    md.production_company
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2023 
    AND md.total_cast > 10
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
This SQL query creates a recursive Common Table Expression (CTE) to build a movie hierarchy based on linked movies, ranks the cast for each movie, gathers details, and filters for more contemporary films with significant casts.
