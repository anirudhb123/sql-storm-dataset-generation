WITH MovieRoles AS (
    SELECT
        c.movie_id,
        c.person_id,
        ct.kind AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        comp_cast_type ct ON c.person_role_id = ct.id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT DISTINCT ak.name ORDER BY ak.name) AS aka_names
    FROM
        aka_title ak
    JOIN
        title m ON ak.movie_id = m.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
),
CompleteCast AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.subject_id) AS total_cast
    FROM
        complete_cast mc
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    md.aka_names,
    COALESCE(cc.total_cast, 0) AS total_cast,
    CASE 
        WHEN cc.total_cast > 5 THEN 'Large Cast'
        WHEN cc.total_cast BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM
    MovieDetails md
LEFT JOIN
    CompleteCast cc ON md.movie_id = cc.movie_id
WHERE
    md.production_year > 2000
ORDER BY
    md.production_year DESC, md.keyword_count DESC;
