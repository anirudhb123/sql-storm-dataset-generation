WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
PersonRoles AS (
    SELECT
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM
        aka_name a
    LEFT JOIN
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        a.person_id
),
MovieStatus AS (
    SELECT
        cc.id AS movie_id,
        COALESCE(m.status_id, 0) AS status,
        COUNT(DISTINCT cc.subject_id) AS cast_count
    FROM
        complete_cast cc
    LEFT JOIN
        movie_info m ON cc.movie_id = m.movie_id
    GROUP BY
        cc.id, m.status_id
)
SELECT
    rm.title,
    r.projection_year,
    COUNT(DISTINCT pc.person_id) AS unique_people_count,
    mv.genres,
    ps.roles AS person_roles,
    ms.cast_count,
    CASE 
        WHEN ms.status = 1 THEN 'Active'
        WHEN ms.status = 2 THEN 'Inactive'
        ELSE 'Unknown'
    END AS status_description
FROM
    RankedMovies rm
LEFT JOIN
    PersonRoles pc ON rm.title_id = pc.movie_count
LEFT JOIN
    MovieGenres mv ON rm.title_id = mv.movie_id
LEFT JOIN
    MovieStatus ms ON rm.title_id = ms.movie_id
WHERE
    rm.rank <= 5
    AND mv.genres LIKE '%Drama%'
    AND (pc.movie_count IS NOT NULL OR pc.roles IS NULL)
GROUP BY
    rm.title,
    rm.production_year,
    mv.genres,
    ps.roles,
    ms.cast_count,
    ms.status
ORDER BY
    unique_people_count DESC;
