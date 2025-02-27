WITH MovieTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN aka_name p ON cc.subject_id = p.person_id
    WHERE t.production_year >= 2000
    AND k.keyword IS NOT NULL
),
RankedMovies AS (
    SELECT 
        mt.movie_title,
        mt.production_year,
        mt.movie_keyword,
        mt.company_name,
        mt.person_name,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_keyword ORDER BY mt.production_year DESC) AS rank
    FROM MovieTitles mt
)
SELECT 
    r.rank,
    r.movie_title,
    r.production_year,
    r.movie_keyword,
    r.company_name,
    r.person_name
FROM RankedMovies r
WHERE r.rank <= 5
ORDER BY r.movie_keyword, r.rank;
