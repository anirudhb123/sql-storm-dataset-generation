WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
CastData AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(CONCAT_WS(' ', a.name, COALESCE(nullif(a.name, ''), 'Unknown')), '' ORDER BY ci.nr_order) AS full_cast_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        ci.role_id = (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY
        ci.movie_id
),
MovieInfo AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MAX(CASE WHEN c.kind = 'production' THEN c.name END) AS production_company,
        MIN(CASE WHEN c.kind = 'distributor' THEN c.name END) AS distributor_company
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(mi.total_companies, 0) AS total_companies,
    CD.full_cast_names,
    mi.production_company,
    mi.distributor_company,
    CASE
        WHEN rm.production_year IS NULL THEN 'Year Unknown'
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_group,
    CASE 
        WHEN COUNT(mk.keyword) = 0 THEN 'No keywords' 
        ELSE STRING_AGG(DISTINCT mk.keyword, ', ') 
    END AS movie_keywords
FROM
    RankedMovies rm
LEFT JOIN
    CastData cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = rm.movie_id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, cd.total_cast, mi.total_companies, CD.full_cast_names, mi.production_company, mi.distributor_company
ORDER BY
    rm.production_year DESC,
    rm.title;
