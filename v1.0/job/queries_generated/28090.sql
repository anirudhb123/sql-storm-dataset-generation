WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM
        aka_title m
        JOIN movie_keyword mk ON mk.movie_id = m.id
        JOIN keyword k ON k.id = mk.keyword_id
        JOIN cast_info ci ON ci.movie_id = m.id
        JOIN aka_name a ON a.person_id = ci.person_id
        JOIN movie_companies mc ON mc.movie_id = m.id
        JOIN company_name c ON c.id = mc.company_id
        JOIN role_type r ON r.id = ci.role_id
    WHERE
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY
        m.id, m.title, m.production_year, k.keyword, c.name
), ActorStats AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT md.movie_id) AS movie_count,
        STRING_AGG(DISTINCT md.title, ', ') AS movies
    FROM
        aka_name a
        JOIN cast_info ci ON ci.person_id = a.person_id
        JOIN MovieDetails md ON md.movie_id = ci.movie_id
    GROUP BY
        a.name
), CompanyStats AS (
    SELECT
        c.name AS company_name,
        COUNT(DISTINCT md.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT md.title) AS movies
    FROM
        company_name c
        JOIN movie_companies mc ON mc.company_id = c.id
        JOIN MovieDetails md ON md.movie_id = mc.movie_id
    GROUP BY
        c.name
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    ARRAY_AGG(DISTINCT ast.actor_name) AS actor_names,
    ARRAY_AGG(DISTINCT cst.company_name) AS involved_companies,
    (SELECT COUNT(*) FROM ActorStats WHERE movie_count > 10) AS prolific_actors_count,
    (SELECT COUNT(*) FROM CompanyStats WHERE movie_count > 5) AS frequent_producers_count
FROM
    MovieDetails md
    JOIN ActorStats ast ON md.actor_names @> ARRAY[ast.actor_name]
    JOIN CompanyStats cst ON md.company_name = cst.company_name
GROUP BY
    md.movie_id, md.title, md.production_year, md.keyword;
