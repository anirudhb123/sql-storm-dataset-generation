WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank,
        ARRAY_AGG(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
actor_roles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM aka_name a
    LEFT JOIN cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY a.person_id, a.name
),
movie_info_with_roles AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mci.company_count, 0) AS company_count,
        COALESCE(ar.movie_count, 0) AS actor_count,
        m.production_year,
        CASE 
            WHEN COALESCE(mci.company_count, 0) = 0 THEN 'No Companies'
            WHEN COALESCE(ar.movie_count, 0) IS NULL THEN 'No Actors'
            ELSE 'Various'
        END AS info_status
    FROM aka_title m
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT company_id) AS company_count
        FROM movie_companies
        GROUP BY movie_id
    ) mci ON m.id = mci.movie_id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS movie_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ) ar ON m.id = ar.movie_id
),
final_benchmark AS (
    SELECT 
        mt.title as movie_title,
        mt.production_year,
        arr.roles AS actor_roles,
        rt.keywords AS movie_keywords,
        mt.info_status
    FROM movie_info_with_roles mt
    LEFT JOIN actor_roles arr ON mt.actor_count > 0 AND mt.movie_id IN (SELECT movie_id FROM cast_info ci WHERE ci.person_id = arr.person_id)
    LEFT JOIN ranked_titles rt ON mt.title = rt.title AND mt.production_year = rt.production_year 
    WHERE mt.production_year >= 2000 AND mt.info_status <> 'No Companies'
)
SELECT
    movie_title,
    production_year,
    actor_roles,
    movie_keywords,
    CASE
        WHEN movie_keywords IS NULL THEN 'Unknown Keywords'
        ELSE 'Keywords Available'
    END AS keyword_status
FROM final_benchmark
ORDER BY production_year DESC, movie_title
LIMIT 50;
