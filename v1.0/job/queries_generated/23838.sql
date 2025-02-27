WITH RecursiveRoleNames AS (
    SELECT
        ci.person_id,
        rt.role AS person_role,
        1 AS level
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    UNION ALL
    SELECT
        ci.person_id,
        rt.role AS person_role,
        r.level + 1
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    JOIN
        RecursiveRoleNames r ON ci.person_id = r.person_id
    WHERE
        r.level < 5
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.prod_year, 0) AS production_year,
        COALESCE(ARRAY_AGG(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), '{}'::text[]) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mi.info_type_id) AS row_num
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    GROUP BY
        m.id
),
FilteredMovies AS (
    SELECT
        mv.movie_id,
        mv.title,
        mv.production_year,
        mv.keywords
    FROM
        MovieInfo mv
    WHERE
        mv.production_year > 2000
        AND EXISTS (
            SELECT 1
            FROM aka_name ak
            WHERE ak.person_id IN (
                SELECT DISTINCT person_id
                FROM cast_info ci
                WHERE ci.movie_id = mv.movie_id
            )
            AND ak.name ILIKE '%actor%'
        )
),
RankedMovies AS (
    SELECT
        fm.*,
        RANK() OVER (ORDER BY fm.production_year DESC) AS rank
    FROM
        FilteredMovies fm
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(STRING_AGG(DISTINCT rn.person_role, ', '), 'No role specified') AS roles,
    CASE 
        WHEN array_length(rm.keywords, 1) > 0 THEN 
            CONCAT('Keywords: ', array_to_string(rm.keywords, ', '))
        ELSE 
            'No keywords available'
    END AS keyword_info,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year not available'
        ELSE 'Year available'
    END AS year_info
FROM
    RankedMovies rm
LEFT JOIN
    RecursiveRoleNames rn ON rn.person_id IN (
        SELECT DISTINCT person_id
        FROM cast_info ci
        WHERE ci.movie_id = rm.movie_id
    )
WHERE 
    rm.rank <= 10
GROUP BY
    rm.movie_id,
    rm.title,
    rm.production_year
ORDER BY
    rm.production_year DESC;
