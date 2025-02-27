WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cp.kind) AS company_types,
        ARRAY_AGG(DISTINCT c.role) AS cast_roles
    FROM
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_type cp ON mc.company_type_id = cp.id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN role_type c ON ci.role_id = c.id
    GROUP BY
        m.id
),
PersonDetails AS (
    SELECT
        p.id AS person_id,
        p.name,
        p.gender,
        ARRAY_AGG(DISTINCT pi.info) AS person_info
    FROM
        name p
    LEFT JOIN person_info pi ON p.id = pi.person_id
    GROUP BY
        p.id
),
DetailedCast AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        pd.person_id,
        pd.name AS actor_name,
        pd.gender,
        md.keywords,
        md.company_types,
        md.cast_roles
    FROM
        MovieDetails md
    JOIN cast_info ci ON md.movie_id = ci.movie_id
    JOIN PersonDetails pd ON ci.person_id = pd.person_id
)
SELECT
    dc.movie_id,
    dc.title,
    dc.production_year,
    STRING_AGG(DISTINCT dc.actor_name, ', ') AS actors,
    dc.keywords,
    dc.company_types,
    dc.cast_roles
FROM
    DetailedCast dc
GROUP BY
    dc.movie_id,
    dc.title,
    dc.production_year
ORDER BY
    dc.production_year DESC, 
    dc.movie_id
LIMIT 10;
