WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year > 2000
)
SELECT
    ak.name AS actor_name,
    cm.name AS company_name,
    rm.title AS movie_title,
    rm.production_year,
    rm.keyword
FROM
    RankedMovies rm
JOIN
    complete_cast cc ON rm.title = cc.movie_id
JOIN
    cast_info ci ON cc.id = ci.movie_id
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    movie_companies mc ON rm.title = mc.movie_id
JOIN
    company_name cm ON mc.company_id = cm.id
WHERE
    rm.rn = 1
    AND cm.country_code = 'USA'
ORDER BY
    rm.production_year DESC, ak.name;
