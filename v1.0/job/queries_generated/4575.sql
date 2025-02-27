WITH MovieRoles AS (
    SELECT
        c.movie_id,
        p.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        aka_name p ON c.person_id = p.person_id
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT cr.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS actor_names
    FROM
        aka_title t
    LEFT JOIN
        MovieRoles cr ON t.id = cr.movie_id
    LEFT JOIN
        aka_name a ON cr.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    cs.company_count,
    cs.company_names
FROM
    MovieDetails md
LEFT JOIN
    KeywordStats ks ON md.movie_id = ks.movie_id
LEFT JOIN
    CompanyInfo cs ON md.movie_id = cs.movie_id
WHERE
    md.production_year >= 2000
    AND md.cast_count > 5
ORDER BY
    md.production_year DESC, 
    md.cast_count DESC;
