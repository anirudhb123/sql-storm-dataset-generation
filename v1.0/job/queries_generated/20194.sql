WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
FinalMovieData AS (
    SELECT
        t.title,
        t.production_year,
        c.name AS company_name,
        co.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN LENGTH(ci.note) ELSE 0 END) AS average_note_length
    FROM
        RankedTitles rt
    LEFT JOIN movie_companies mc ON rt.title_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type co ON mc.company_type_id = co.id
    LEFT JOIN cast_info ci ON rt.title_id = ci.movie_id
    GROUP BY
        rt.title,
        rt.production_year,
        c.name,
        co.kind
),
ActorInfo AS (
    SELECT
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS average_info_length
    FROM
        aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN person_info pi ON ak.person_id = pi.person_id
    GROUP BY
        ak.name
),
KeywordStats AS (
    SELECT
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT k.id) AS total_keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY
        m.id
)
SELECT
    f.title,
    f.production_year,
    f.company_name,
    f.company_type,
    f.num_actors,
    f.role_count,
    f.average_note_length,
    COALESCE(ai.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(ai.movies_count, 0) AS actor_movie_count,
    COALESCE(ai.average_info_length, 0) AS actor_average_info_length,
    k.keywords,
    k.total_keywords
FROM
    FinalMovieData f
LEFT JOIN ActorInfo ai ON f.num_actors = ai.movies_count -- intentionally unusual condition
LEFT JOIN KeywordStats k ON f.title = ANY(k.keywords) -- bizarre logic for matching keywords
WHERE
    f.production_year >= 2000 AND
    (f.role_count > 5 OR f.num_actors = 0) -- complex predicate
ORDER BY
    f.production_year DESC,
    f.title_rank NULLS LAST;
