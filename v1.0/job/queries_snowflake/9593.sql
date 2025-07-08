WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, c.name, k.keyword
),
RankedMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        company_name, 
        movie_keyword, 
        actors,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actors) DESC) AS rank
    FROM MovieDetails
    GROUP BY movie_title, production_year, company_name, movie_keyword, actors
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.company_name,
    rm.movie_keyword,
    rm.actors
FROM RankedMovies rm
WHERE rm.rank <= 5
ORDER BY rm.production_year DESC, rm.rank;
