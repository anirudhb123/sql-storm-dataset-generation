WITH MovieRoles AS (
    SELECT
        c.movie_id,
        r.role AS person_role,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', a.md5sum, ')'), ', ') AS actor_names
    FROM
        cast_info c
    JOIN
        role_type r ON c.person_role_id = r.id
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id, r.role
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(mr.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'None') AS keywords,
        COALESCE(mi.info, 'No info') AS additional_info,
        COALESCE(CG.company_group, 'Unknown') AS company_contributors
    FROM
        title m
    LEFT JOIN
        MovieRoles mr ON m.id = mr.movie_id
    LEFT JOIN
        MovieKeywords mk ON m.id = mk.movie_id
    LEFT JOIN (
        SELECT
            mc.movie_id,
            STRING_AGG(cn.name, ', ') AS company_group
        FROM
            movie_companies mc
        JOIN
            company_name cn ON mc.company_id = cn.id
        GROUP BY
            mc.movie_id
    ) CG ON m.id = CG.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
)

SELECT
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.total_actors,
    mi.keywords,
    mi.additional_info,
    k.kind AS movie_kind,
    ROW_NUMBER() OVER (PARTITION BY mi.production_year ORDER BY mi.total_actors DESC) AS rank_by_actors
FROM
    MovieInfo mi
JOIN
    kind_type k ON mi.kind_id = k.id
WHERE
    mi.production_year IS NOT NULL
ORDER BY
    mi.production_year DESC,
    mi.total_actors DESC;
