WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON c.movie_id = t.movie_id
    LEFT JOIN
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON c.id = mc.company_id
    JOIN
        company_type ct ON ct.id = mc.company_type_id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(CASE WHEN it.info = 'Plot' THEN mi.info END, ' ') AS plot_info,
        STRING_AGG(CASE WHEN it.info = 'Genre' THEN mi.info END, ', ') AS genre_info
    FROM
        movie_info mi
    JOIN
        info_type it ON it.id = mi.info_type_id
    GROUP BY
        mi.movie_id
)
SELECT
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.all_cast,
    md.keywords,
    co.company_name,
    co.company_type,
    mi.plot_info,
    mi.genre_info
FROM
    MovieDetails md
LEFT JOIN
    CompanyDetails co ON co.movie_id = md.movie_id
LEFT JOIN
    MovieInfo mi ON mi.movie_id = md.movie_id
ORDER BY
    md.production_year DESC, md.movie_title;
