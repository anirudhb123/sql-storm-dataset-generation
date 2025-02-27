WITH movie_aliases AS (
    SELECT
        a.id AS alias_id,
        a.name AS alias_name,
        at.title AS movie_title,
        at.production_year,
        at.imdb_index AS movie_index,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM
        aka_name a
    JOIN
        aka_title at ON a.person_id = at.movie_id
    JOIN
        cast_info ci ON at.id = ci.movie_id
    GROUP BY
        a.id, at.id
),

company_details AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS total_movies_produced
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id, c.name, ct.kind
),

keyword_stats AS (
    SELECT
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS usage_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id, k.keyword
)

SELECT
    ma.alias_name,
    ma.movie_title,
    ma.production_year,
    ma.movie_index,
    cd.company_name,
    cd.company_type,
    ks.keyword,
    ks.usage_count
FROM
    movie_aliases ma
LEFT JOIN
    company_details cd ON ma.movie_title = cd.movie_id
LEFT JOIN
    keyword_stats ks ON ma.movie_title = ks.movie_id
ORDER BY
    ma.production_year DESC,
    ma.alias_name ASC,
    cd.company_name ASC;
