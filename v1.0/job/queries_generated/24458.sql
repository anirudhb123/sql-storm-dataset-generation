WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank_per_year
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank_per_year <= 5
),
PersonRoles AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ci.nr_order
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
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
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(p.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(pr.role_name, 'No Role') AS role_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM
    TopMovies tm
LEFT JOIN
    PersonRoles p ON tm.movie_id = p.movie_id
LEFT JOIN
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    (SELECT
        movie_id,
        COUNT(*) AS role_count
     FROM
        PersonRoles
     GROUP BY
        movie_id
    HAVING COUNT(*) > 1
    ) AS pr_count ON tm.movie_id = pr_count.movie_id
LEFT JOIN
    role_type pr ON p.role_name = pr.role
WHERE
    tm.production_year IS NOT NULL 
    AND (tm.title LIKE '%Batman%' OR mk.keywords LIKE '%action%' OR mk.keywords IS NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC
LIMIT 100;
