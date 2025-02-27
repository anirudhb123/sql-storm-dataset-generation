WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT CONCAT(s.intro_year, ': ', s.title) ORDER BY s.intro_year) AS series_info,
        GROUP_CONCAT(DISTINCT i.info ORDER BY i.info_type_id) AS additional_info
    FROM
        title m
    LEFT JOIN
        movie_info i ON m.id = i.movie_id
    LEFT JOIN
        (SELECT DISTINCT ON (p.id) p.id AS intro_year, p.title FROM title p ORDER BY p.production_year DESC) s ON m.id = s.id
    GROUP BY
        m.id
)
SELECT
    mt.title_id,
    mt.title,
    mt.production_year,
    cd.actor_name,
    cd.role,
    mt.series_info,
    mt.additional_info,
    r.keyword AS top_keyword
FROM
    RankedTitles mt
JOIN
    CastDetails cd ON mt.title_id = cd.movie_id
LEFT JOIN
    (SELECT title_id, keyword FROM RankedTitles WHERE keyword_rank = 1) r ON mt.title_id = r.title_id
WHERE
    mt.production_year >= 2000
ORDER BY
    mt.production_year DESC, cd.actor_rank;

