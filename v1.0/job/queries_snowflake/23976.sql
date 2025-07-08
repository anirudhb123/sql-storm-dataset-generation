WITH Recursive TopMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT
        ak.person_id,
        ak.name,
        ci.movie_id,
        rt.role AS role,
        COUNT(*) OVER (PARTITION BY ak.person_id ORDER BY ci.nr_order) AS role_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
MoviesWithKeywords AS (
    SELECT
        t.id AS movie_id,
        t.title,
        k.keyword,
        COALESCE(mk.movie_id, NULL) AS keyword_movie_id
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        COUNT(DISTINCT ct.kind) AS distinct_company_types
    FROM
        movie_companies mc
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT DISTINCT
    tm.title,
    tm.production_year,
    ar.name AS actor_name,
    ar.role,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
    cs.total_companies,
    cs.distinct_company_types,
    CASE
        WHEN ar.role_count > 3 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_frequent_category
FROM
    TopMovies tm
LEFT JOIN
    ActorRoles ar ON tm.movie_id = ar.movie_id
LEFT JOIN
    MoviesWithKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    CompanyStats cs ON tm.movie_id = cs.movie_id
WHERE
    tm.rn <= 10 
    AND (ar.role IS NOT NULL OR mk.keyword IS NOT NULL)
ORDER BY
    tm.production_year ASC, 
    tm.title, 
    actor_frequent_category DESC;
