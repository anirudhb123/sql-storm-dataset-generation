WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        company_type ct ON c.id = ct.id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(ci.id) OVER (PARTITION BY ci.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_number
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
NullRoleMovies AS (
    SELECT 
        ci.movie_id
    FROM 
        cast_info ci
    WHERE
        ci.note IS NULL
    GROUP BY 
        ci.movie_id
)

SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT ci.company_name, ', ') AS companies,
    COUNT(DISTINCT cd.actor_name) AS total_actors,
    SUM(CASE WHEN cd.actor_count > 1 THEN 1 ELSE 0 END) AS movies_with_multiple_actors,
    (SELECT COUNT(*) FROM CastDetails WHERE movie_id = tm.title_id AND actor_number = 1) AS first_actor_id
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    CompanyInfo ci ON mc.company_id = ci.company_id
LEFT JOIN 
    CastDetails cd ON tm.title_id = cd.movie_id
WHERE 
    tm.title_id NOT IN (SELECT movie_id FROM NullRoleMovies)
GROUP BY 
    tm.title_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT ci.company_name) > 1 
ORDER BY 
    tm.production_year DESC, tm.title;
