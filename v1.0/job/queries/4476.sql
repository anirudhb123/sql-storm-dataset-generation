WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS movie_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_movie AS (
    SELECT 
        ca.movie_id, 
        ak.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM cast_info ca
    JOIN aka_name ak ON ca.person_id = ak.person_id
    GROUP BY ca.movie_id, ak.name
),
company_movies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_count,
        cm.company_names
    FROM ranked_movies rm
    LEFT JOIN actor_movie am ON rm.movie_id = am.movie_id
    LEFT JOIN company_movies cm ON rm.movie_id = cm.movie_id
    WHERE rm.movie_rank <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_count, 0) AS total_actors,
    COALESCE(fm.company_names, 'No Companies') AS companies_involved
FROM filtered_movies fm
ORDER BY fm.production_year DESC, total_actors DESC;
