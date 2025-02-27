WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.person_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    an.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    COALESCE(ak.keywords, 'No keywords') AS keywords,
    ac.movie_count,
    CASE WHEN ac.movie_count > 10 THEN 'Veteran' 
         WHEN ac.movie_count > 5 THEN 'Established' 
         ELSE 'Newcomer' END AS actor_status
FROM ranked_titles rt
JOIN cast_info ci ON rt.title_id = ci.movie_id
JOIN aka_name an ON ci.person_id = an.person_id
LEFT JOIN actor_movie_counts ac ON an.person_id = ac.person_id
LEFT JOIN movie_keywords ak ON rt.title_id = ak.movie_id
WHERE rt.rank <= 5
ORDER BY rt.production_year, actor_name;
