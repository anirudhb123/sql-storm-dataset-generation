WITH movie_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword
    FROM title t
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year >= 2000 AND t.kind_id IN (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
), actor_details AS (
    SELECT
        ka.name AS actor_name,
        ka.person_id,
        GROUP_CONCAT(DISTINCT a.title ORDER BY a.production_year DESC) AS movies
    FROM aka_name ka
    JOIN cast_info ci ON ci.person_id = ka.person_id
    JOIN movie_titles a ON a.title_id = ci.movie_id
    GROUP BY ka.id, ka.name, ka.person_id
), company_info AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON c.id = mc.company_id
    JOIN company_type ct ON ct.id = mc.company_type_id
), final_benchmark AS (
    SELECT
        ad.actor_name,
        ad.movies,
        ci.company_name,
        ci.company_type,
        COUNT(DISTINCT ci.company_name) AS company_count
    FROM actor_details ad
    JOIN cast_info ci ON ci.person_id = ad.person_id
    JOIN company_info ci ON ci.movie_id = ci.movie_id
    GROUP BY ad.actor_name, ad.movies, ci.company_name, ci.company_type
    ORDER BY company_count DESC
)
SELECT *
FROM final_benchmark
WHERE company_count > 1
ORDER BY actor_name;
