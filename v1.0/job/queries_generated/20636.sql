WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CompaniesWithMoreThanTwoFilms AS (
    SELECT
        mc.company_id,
        COUNT(mc.movie_id) AS film_count
    FROM
        movie_companies mc
    GROUP BY
        mc.company_id
    HAVING
        COUNT(mc.movie_id) > 2
),
ActorsWithDiverseRoles AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE
        rt.role IS NOT NULL
    GROUP BY
        ci.person_id
    HAVING
        COUNT(DISTINCT ci.role_id) >= 3
),
MoviesWithKeywords AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id
)
SELECT
    c.name AS company_name,
    t.title AS movie_title,
    t.production_year,
    a.name AS actor_name,
    rk.keywords,
    COALESCE(actors.role_count, 0) AS distinct_role_count,
    CASE WHEN c.company_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_multiple_films
FROM
    CompaniesWithMoreThanTwoFilms c
JOIN 
    movie_companies mc ON c.company_id = mc.company_id
JOIN 
    aka_title t ON mc.movie_id = t.id
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MoviesWithKeywords rk ON t.id = rk.movie_id
LEFT JOIN 
    ActorsWithDiverseRoles actors ON ci.person_id = actors.person_id
WHERE
    t.production_year > 2000
    AND (a.name IS NOT NULL OR mc.note IS NOT NULL)
ORDER BY
    t.production_year DESC,
    c.name,
    distinct_role_count DESC,
    movie_title ASC
LIMIT 100;
