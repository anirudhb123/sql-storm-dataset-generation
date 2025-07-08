
WITH MovieInfoCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = mt.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
),
KeywordDetails AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    COALESCE(cd.company_name, 'Not Available') AS company_name,
    COALESCE(cd.company_type, 'Not Specified') AS company_type,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    m.year_rank
FROM
    MovieInfoCTE m
LEFT JOIN
    CompanyDetails cd ON m.movie_id = cd.movie_id
LEFT JOIN
    KeywordDetails kw ON m.movie_id = kw.movie_id
WHERE
    m.total_cast > 1
ORDER BY
    m.production_year DESC,
    m.title;
