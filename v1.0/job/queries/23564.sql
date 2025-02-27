
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CoActors AS (
    SELECT
        c.id AS cast_id,
        a.id AS person_id,
        a.name,
        COUNT(DISTINCT c2.movie_id) AS co_starring_count
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN cast_info c2 ON c.movie_id = c2.movie_id AND c.person_id <> c2.person_id
    GROUP BY
        c.id, a.id, a.name
),
MovieCompanyDetails AS (
    SELECT
        mc.movie_id,
        mc.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(m.note, 'No additional notes') AS note
    FROM
        movie_companies mc
    LEFT JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info m ON mc.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Notes')
),
DistinctKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    a.name AS actor_name,
    COALESCE(d.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(co.co_starring_count) AS avg_co_stars
FROM
    RankedTitles t
LEFT JOIN cast_info ci ON t.title_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN DistinctKeywords d ON t.title_id = d.movie_id
LEFT JOIN MovieCompanyDetails mc ON t.title_id = mc.movie_id
LEFT JOIN CoActors co ON a.person_id = co.person_id
WHERE
    t.rank = 1
GROUP BY
    t.title, t.production_year, a.name, d.keywords
HAVING
    COUNT(DISTINCT mc.company_id) >= 1
ORDER BY
    t.production_year DESC, avg_co_stars DESC;
