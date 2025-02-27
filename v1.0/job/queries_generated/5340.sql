WITH MovieCast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
MovieCompanies AS (
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
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(MI.info, ', ') AS info_details
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT mc.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(mca.actor_name, ' (', mca.role, ')'), ', ') AS cast,
    mi.info_details
FROM
    title t
LEFT JOIN
    MovieCompanies mc ON t.id = mc.movie_id
LEFT JOIN
    MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN
    MovieCast mca ON t.id = mca.movie_id
LEFT JOIN
    MovieInfo mi ON t.id = mi.movie_id
GROUP BY
    t.id, t.title, t.production_year, mi.info_details
ORDER BY
    t.production_year DESC, t.title;
