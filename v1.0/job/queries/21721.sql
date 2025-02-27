
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_by_title,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.id, a.title, a.production_year
),
MovieCompanyInfo AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No info available') AS movie_info,
        (SELECT COUNT(*) FROM movie_companies WHERE movie_id = mc.movie_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN
        movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Plot'
        )
)
SELECT
    rm.title,
    rm.production_year,
    COUNT(ci.id) AS cast_member_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS non_null_notes_count,
    MIN(CASE WHEN mc.company_type = 'Distributor' THEN mc.company_name END) AS distributor_name,
    MAX(mc.company_count) AS max_company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.role_id IS NOT NULL) AS distinct_roles
FROM
    RankedMovies rm
LEFT JOIN
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    MovieCompanyInfo mc ON rm.movie_id = mc.movie_id
LEFT JOIN
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, rm.rank_by_title
HAVING
    COUNT(ci.id) > 5
ORDER BY
    rm.production_year DESC, rank_by_title ASC;
