WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_aggregated AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name || ' (' || ct.kind || ')') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
final_output AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ca.total_cast,
        ca.cast_names,
        co.companies
    FROM ranked_movies rm
    LEFT JOIN cast_aggregated ca ON rm.movie_id = ca.movie_id
    LEFT JOIN company_details co ON rm.movie_id = co.movie_id
)
SELECT 
    *
FROM final_output
WHERE rank <= 10
ORDER BY production_year DESC, movie_id;
