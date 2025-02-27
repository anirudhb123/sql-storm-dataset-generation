
WITH movie_cast AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        STRING_AGG(DISTINCT a.imdb_index) AS actor_indexes
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id, a.name
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
all_movies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        tc.kind AS title_kind,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.num_actors, 0) AS num_actors,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS complete_cast_count,
        (SELECT COUNT(*) 
         FROM movie_info mi 
         WHERE mi.movie_id = t.id AND 
               mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'General')) AS general_info_count
    FROM
        title t
    LEFT JOIN
        kind_type tc ON t.kind_id = tc.id
    LEFT JOIN
        movie_keywords mk ON t.id = mk.movie_id
    LEFT JOIN
        movie_cast mc ON t.id = mc.movie_id
)
SELECT
    am.title_id,
    am.title,
    am.production_year,
    am.title_kind,
    am.keywords,
    am.num_actors,
    am.complete_cast_count,
    am.general_info_count,
    RANK() OVER (PARTITION BY am.title_kind ORDER BY am.num_actors DESC) AS actor_rank,
    CASE
        WHEN am.complete_cast_count = 0 THEN 'No complete cast available'
        ELSE 'Complete cast available'
    END AS cast_availability,
    (SELECT STRING_AGG(DISTINCT c.name, ', ')
     FROM company_name c
     JOIN movie_companies mc ON c.id = mc.company_id
     WHERE mc.movie_id = am.title_id) AS production_companies
FROM
    all_movies am
WHERE
    am.production_year BETWEEN 2000 AND 2023 
    AND (am.keywords LIKE '%Action%' OR am.keywords LIKE '%Drama%' OR am.keywords IS NULL)
ORDER BY
    am.production_year DESC,
    actor_rank;
