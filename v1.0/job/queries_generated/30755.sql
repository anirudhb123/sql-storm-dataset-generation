WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
),
movie_actors AS (
    SELECT 
        c.movie_id,
        COALESCE(a.name, 'Unknown') AS actor_name
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    ma.actor_name,
    COALESCE(cm.company_names, 'No Companies') AS companies
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_actors ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    company_movies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.rank, ma.actor_name;
