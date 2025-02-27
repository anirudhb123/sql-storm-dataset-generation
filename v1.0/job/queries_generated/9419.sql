WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT co.name) AS companies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        companies,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    companies,
    keywords
FROM TopMovies
WHERE rank <= 10
ORDER BY production_year DESC, cast_count DESC;
