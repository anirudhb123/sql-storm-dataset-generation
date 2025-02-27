WITH RECURSIVE YearRanking AS (
    SELECT
        title.production_year,
        title.title,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM
        title
    WHERE
        title.production_year IS NOT NULL
),
MovieCast AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        cc.kind AS role_type,
        CASE
            WHEN c.nr_order IS NULL THEN 'Unassigned'
            ELSE 'Assigned'
        END AS assignment_status
    FROM
        title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN comp_cast_type cc ON c.person_role_id = cc.id
),
CompanyInfo AS (
    SELECT
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.id) AS company_count
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        m.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.info AS movie_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM
        movie_info m
    JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    WHERE
        m.info IS NOT NULL
    GROUP BY
        m.movie_id
)

SELECT
    t.title,
    t.production_year,
    CONCAT('Rank: ', yr.rank, ', Keywords: ', md.keyword_count) AS details,
    mc.actor_name,
    mc.role_type,
    co.company_names,
    co.company_count,
    CASE
        WHEN mc.assignment_status = 'Assigned' THEN 'Actor Assigned'
        ELSE 'No Actor Assigned'
    END AS actor_assignment
FROM
    title t
LEFT JOIN YearRanking yr ON t.production_year = yr.production_year
LEFT JOIN MovieCast mc ON t.title = mc.title AND t.production_year = mc.production_year
LEFT JOIN CompanyInfo co ON t.id = co.movie_id
LEFT JOIN MovieDetails md ON t.id = md.movie_id
WHERE
    t.kind_id IN (
        SELECT id FROM kind_type WHERE kind = 'movie'
    )
ORDER BY
    t.production_year DESC, mc.actor_name ASC NULLS LAST;
