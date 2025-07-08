
WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_members,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM
        aka_title m
    JOIN
        cast_info ci ON m.id = ci.movie_id
    JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        m.id, m.title, m.production_year
), CompanyDetails AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
), FullDetails AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.cast_members,
        md.keywords,
        cd.company_names,
        cd.company_types
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT
    fd.movie_id,
    fd.movie_title,
    fd.production_year,
    fd.cast_members,
    fd.keywords,
    fd.company_names,
    fd.company_types
FROM
    FullDetails fd
WHERE
    fd.production_year >= 2000
ORDER BY
    fd.production_year DESC,
    fd.movie_title ASC;
