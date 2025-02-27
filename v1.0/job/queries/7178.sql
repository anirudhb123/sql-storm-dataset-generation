WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        t.id, t.title, t.production_year, k.keyword
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
FullMovieDetails AS (
    SELECT
        md.title_id,
        md.title,
        md.production_year,
        md.movie_keyword,
        md.cast_names,
        cd.company_name,
        cd.company_type
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyDetails cd ON md.title_id = cd.movie_id
)
SELECT
    fmd.title,
    fmd.production_year,
    fmd.movie_keyword,
    fmd.cast_names,
    ARRAY_AGG(DISTINCT fmd.company_name) AS companies,
    ARRAY_AGG(DISTINCT fmd.company_type) AS company_types
FROM
    FullMovieDetails fmd
GROUP BY
    fmd.title, fmd.production_year, fmd.movie_keyword, fmd.cast_names
ORDER BY
    fmd.production_year DESC, fmd.title;
