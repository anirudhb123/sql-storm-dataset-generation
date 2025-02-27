WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
CompanyMovieDetails AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, co.name, ct.kind
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
FinalResults AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names,
        COALESCE(cmp.company_name, 'Unknown') AS company_name,
        COALESCE(cmp.company_type, 'Unknown') AS company_type,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM
        MovieDetails md
    LEFT JOIN
        CompanyMovieDetails cmp ON md.movie_id = cmp.movie_id
    LEFT JOIN
        MovieKeywords mk ON md.movie_id = mk.movie_id
)
SELECT
    movie_id,
    title,
    production_year,
    cast_count,
    cast_names,
    company_name,
    company_type,
    keywords
FROM
    FinalResults
WHERE
    production_year > 2000
ORDER BY
    production_year DESC, cast_count DESC
LIMIT 50;

