WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
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
company_movies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cm.company_names, 'No companies') AS company_names,
    COALESCE(cm.company_types, 'No types') AS company_types
FROM
    ranked_movies rm
LEFT JOIN
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    company_movies cm ON rm.movie_id = cm.movie_id
WHERE
    (rm.actor_count > 5 OR rm.production_year >= 2000)
    AND rm.rank <= 10
ORDER BY
    rm.production_year DESC,
    rm.actor_count DESC;
