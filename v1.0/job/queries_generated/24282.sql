WITH ranked_cast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ak.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
),
movie_titles AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(MAX(mk.keyword), 'No keywords') AS primary_keyword,
        mt.production_year,
        COUNT(DISTINCT r.id) AS role_count
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN
        role_type r ON mc.company_type_id = r.id
    GROUP BY
        mt.id, mt.title, mt.production_year
),
complex_joins AS (
    SELECT
        mv.movie_id,
        mv.title,
        mv.production_year,
        rc.actor_name,
        rc.actor_rank,
        rc.total_actors
    FROM
        movie_titles mv
    LEFT JOIN
        ranked_cast rc ON mv.movie_id = rc.movie_id
    WHERE
        (rc.actor_rank = 1 OR rc.actor_rank IS NULL) -- Include only lead actors or movies with no actors
        AND mv.production_year >= 2000
        AND mv.primary_keyword NOT LIKE '%action%' -- Exclude action movies specifically if they contain the keyword
)
SELECT 
    cj.title,
    cj.production_year,
    cj.actor_name,
    CASE 
        WHEN cj.actor_rank IS NULL THEN 'No Actors'
        ELSE CONCAT('Actor Rank: ', cj.actor_rank, ' of ', cj.total_actors)
    END AS actor_details,
    CASE 
        WHEN cj.production_year < 2010 THEN 'Pre-2010 Release'
        ELSE 'Post-2009 Release'
    END AS release_category
FROM
    complex_joins cj
ORDER BY 
    cj.production_year DESC,
    cj.title;
