WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info c ON at.movie_id = c.movie_id
    LEFT JOIN
        aka_name an ON c.person_id = an.person_id
    GROUP BY
        at.id, at.title, at.production_year
),
HighActorCountMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        actor_count >= (SELECT AVG(actor_count) FROM RankedMovies)
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
)
SELECT
    ham.title,
    ham.production_year,
    COALESCE(mc.company_name, 'No Company') AS company_name,
    COUNT(DISTINCT km.keyword) AS keyword_count
FROM
    HighActorCountMovies ham
LEFT JOIN
    MovieCompanies mc ON ham.movie_id = mc.movie_id
LEFT JOIN
    movie_keyword mk ON ham.movie_id = mk.movie_id
LEFT JOIN
    keyword km ON mk.keyword_id = km.id
WHERE
    ham.production_year <> 0
GROUP BY
    ham.movie_id, ham.title, ham.production_year, mc.company_name
HAVING
    COUNT(DISTINCT km.id) > 1
ORDER BY
    ham.production_year DESC, keyword_count DESC
LIMIT 10;
