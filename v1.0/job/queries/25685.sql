
WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.phonetic_code,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, t.phonetic_code, k.keyword
),
CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        g.role AS role
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type g ON c.role_id = g.id
    WHERE
        a.name LIKE '%Smith%'
),
FinalDetails AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.phonetic_code,
        md.movie_keyword,
        cd.actor_name,
        cd.role
    FROM
        MovieDetails md
    LEFT JOIN
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT
    fd.movie_id,
    fd.movie_title,
    fd.production_year,
    fd.phonetic_code,
    fd.movie_keyword,
    COALESCE(fd.actor_name, 'No Cast Available') AS actor_name,
    COALESCE(fd.role, 'No Role Available') AS role
FROM
    FinalDetails fd
ORDER BY
    fd.production_year DESC, fd.movie_title ASC;
