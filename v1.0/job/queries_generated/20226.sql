WITH RankedMovies AS (
    SELECT
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) as YearRank,
        COUNT(c.id) OVER (PARTITION BY m.id) AS ActorCount,
        COALESCE(k.keyword, 'Unknown') AS Keyword
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        m.production_year IS NOT NULL
)

SELECT
    rm.title,
    rm.production_year,
    rm.ActorCount,
    rm.Keyword,
    SUM(CASE WHEN c.note IS NULL THEN 0 ELSE 1 END) AS NonNullNotes,
    STRING_AGG(DISTINCT COALESCE(a.name, 'Anonymous'), ', ') AS ActorNames
FROM
    RankedMovies rm
LEFT JOIN
    cast_info c ON c.movie_id IN (SELECT m.id FROM aka_title m WHERE YEAR(m.production_year) = rm.production_year)
LEFT JOIN
    aka_name a ON a.person_id = c.person_id
WHERE
    rm.YearRank <= 10
GROUP BY
    rm.title, rm.production_year, rm.ActorCount, rm.Keyword
HAVING
    COUNT(c.id) > 5 OR SUM(CASE WHEN rm.Keyword IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY
    rm.production_year DESC, rm.ActorCount DESC NULLS LAST;

WITH MovieDetails AS (
    SELECT
        at.id AS movie_id,
        at.title,
        cc.subject_id AS lead_actor_id,
        COALESCE(p.name, 'Unknown') AS lead_actor_name,
        at.production_year,
        mt.kind AS company_type,
        COUNT(DISTINCT m.id) FILTER (WHERE c.note IS NOT NULL) AS NotedCompanies
    FROM
        aka_title at
    LEFT JOIN
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type mt ON mc.company_type_id = mt.id
    LEFT JOIN
        aka_name p ON cc.subject_id = p.person_id
    WHERE
        c.nr_order = 1
    GROUP BY
        at.id, at.title, cc.subject_id, p.name, mt.kind
)

SELECT
    md.title,
    md.lead_actor_name,
    md.production_year,
    md.company_type,
    md.NotedCompanies
FROM
    MovieDetails md
WHERE
    md.NotedCompanies > 2 AND
    (md.company_type IS NOT NULL OR md.lead_actor_name = 'Unknown')
ORDER BY
    md.production_year DESC;

WITH CompanyStats AS (
    SELECT
        c.id AS company_id,
        COUNT(DISTINCT mc.movie_id) AS MovieCount,
        STRING_AGG(DISTINCT CONCAT(mb.first_name, ' ', mb.last_name), ', ') AS Directors
    FROM
        company_name c
    LEFT JOIN
        movie_companies mc ON c.id = mc.company_id
    LEFT JOIN
        (SELECT
            DISTINCT ON (m.id)
            a.name AS first_name,
            a.surname AS last_name,
            mc.movie_id
        FROM
            aka_name a
        JOIN
            cast_info ci ON a.person_id = ci.person_id
        JOIN
            complete_cast cc ON ci.movie_id = cc.movie_id
        JOIN
            aka_title m ON cc.movie_id = m.id
        ORDER BY
            m.id, a.surname, a.name) mb ON mc.movie_id = mb.movie_id
    GROUP BY
        c.id
)

SELECT
    cs.company_id,
    cs.MovieCount,
    LENGTH(cs.Directors) - LENGTH(REPLACE(cs.Directors, ',', '')) + 1 AS DirectorCount
FROM
    CompanyStats cs
WHERE
    cs.MovieCount > 5
ORDER BY
    DirectorCount DESC, cs.MovieCount DESC;
