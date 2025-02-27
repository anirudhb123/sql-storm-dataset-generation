WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.created_at DESC) AS rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS role_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM
        cast_info ci
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.person_id
),
CompanyMovieCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
),
TitleKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
FinalSelection AS (
    SELECT
        rt.title,
        rt.production_year,
        COALESCE(rac.role_count, 0) AS actor_count,
        COALESCE(cmc.company_count, 0) AS company_count,
        COALESCE(tkc.keyword_count, 0) AS keyword_count
    FROM
        RankedTitles rt
    LEFT JOIN ActorRoleCounts rac ON rt.title_id IN (
        SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id IN (
            SELECT DISTINCT person_id FROM aka_name
        )
    )
    LEFT JOIN CompanyMovieCounts cmc ON rt.title_id = cmc.movie_id
    LEFT JOIN TitleKeywordCounts tkc ON rt.title_id = tkc.movie_id
    WHERE
        rt.rank = 1
)
SELECT
    fs.title,
    fs.production_year,
    fs.actor_count,
    fs.company_count,
    fs.keyword_count,
    CASE
        WHEN fs.actor_count > 5 THEN 'Popular'
        WHEN fs.actor_count IS NULL THEN 'Uncertain'
        ELSE 'Unknown'
    END AS popularity_status
FROM
    FinalSelection fs
WHERE
    fs.production_year IS NOT NULL
ORDER BY
    fs.production_year DESC, fs.actor_count DESC
FETCH FIRST 20 ROWS ONLY;

WITH RECURSIVE LinkGraph AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    WHERE
        ml.link_type_id = (
            SELECT id FROM link_type WHERE link = 'related'
        )
    UNION ALL
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        lg.depth + 1
    FROM
        movie_link ml
    JOIN LinkGraph lg ON ml.movie_id = lg.linked_movie_id
)
SELECT
    lg.movie_id,
    COUNT(DISTINCT lg.linked_movie_id) AS total_related
FROM
    LinkGraph lg
GROUP BY
    lg.movie_id
HAVING
    COUNT(DISTINCT lg.linked_movie_id) > 0
ORDER BY
    total_related DESC;

WITH MultiJoinData AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        c.note AS cast_note,
        ck.keyword AS movie_keyword,
        CASE
            WHEN ci.note IS NULL THEN 'No Note'
            ELSE ci.note
        END AS additional_note
    FROM
        aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN keyword ck ON mk.keyword_id = ck.id
)
SELECT
    m.actor_name,
    m.movie_title,
    COUNT(DISTINCT m.movie_keyword) AS keyword_count,
    MAX(m.additional_note) AS latest_note
FROM
    MultiJoinData m
GROUP BY
    m.actor_name, m.movie_title
HAVING
    COUNT(DISTINCT m.movie_keyword) >= 3
ORDER BY
    keyword_count DESC, m.actor_name;
