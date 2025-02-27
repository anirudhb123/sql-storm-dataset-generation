WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
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
actor_details AS (
    SELECT
        p.id AS person_id,
        a.name,
        a.surname_pcode,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS not_null_notes_ratio
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        person_info p ON p.person_id = a.person_id
    GROUP BY
        p.id, a.name, a.surname_pcode
),
company_movie_info AS (
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
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    ad.surname_pcode,
    ad.movie_count,
    ad.not_null_notes_ratio,
    mk.keywords,
    cmi.company_names,
    cmi.company_types
FROM
    ranked_titles rt
LEFT JOIN
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN
    actor_details ad ON ci.person_id = ad.person_id
LEFT JOIN
    movie_keywords mk ON rt.title_id = mk.movie_id
LEFT JOIN
    company_movie_info cmi ON rt.title_id = cmi.movie_id
WHERE
    (rt.production_year > 2000 OR rt.production_year IS NULL)
    AND (ad.movie_count IS NOT NULL OR (ad.not_null_notes_ratio < 0.5 AND ad.movie_count < 10))
ORDER BY
    rt.production_year DESC,
    rt.title ASC;
