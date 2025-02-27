WITH recursive actor_titles AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
),
aggregate_movies AS (
    SELECT 
        actor_id,
        COUNT(*) AS total_movies,
        STRING_AGG(movie_title, ', ' ORDER BY production_year) AS movie_list
    FROM 
        actor_titles
    WHERE 
        title_rank <= 3
    GROUP BY 
        actor_id
),
oldest_movie AS (
    SELECT 
        actor_id,
        MIN(production_year) AS earliest_year
    FROM 
        actor_titles 
    WHERE 
        (actor_id, title_rank) IN (SELECT actor_id, MIN(title_rank) FROM actor_titles GROUP BY actor_id)
    GROUP BY 
        actor_id
)
SELECT 
    ak.name AS actor_name,
    ag.total_movies,
    ag.movie_list,
    om.earliest_year,
    COALESCE(om.earliest_year, 'Unknown Year') AS adjusted_year,
    CASE 
        WHEN ag.total_movies > 5 THEN 'Prolific Actor'
        WHEN ag.total_movies BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Newcomer'
    END AS actor_status
FROM 
    aggregate_movies ag
JOIN 
    aka_name ak ON ag.actor_id = ak.person_id
LEFT JOIN 
    oldest_movie om ON ag.actor_id = om.actor_id
WHERE 
    (adjusted_year IS NULL OR adjusted_year < 2000) 
    AND ak.name_pcode_nf IS NOT NULL
ORDER BY 
    ag.total_movies DESC,
    adjusted_year;
