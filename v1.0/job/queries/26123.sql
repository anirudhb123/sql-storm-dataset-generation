
WITH MovieInfo AS (
    SELECT t.title AS movie_title, t.production_year, 
           k.keyword AS movie_keyword, 
           c.name AS company_name, 
           p.name AS person_name,
           ci.note AS person_role
    FROM aka_title AS t
    JOIN movie_keyword AS mk ON t.id = mk.movie_id
    JOIN keyword AS k ON mk.keyword_id = k.id
    JOIN movie_companies AS mc ON t.id = mc.movie_id
    JOIN company_name AS c ON mc.company_id = c.id
    JOIN cast_info AS ci ON t.id = ci.movie_id
    JOIN aka_name AS p ON ci.person_id = p.person_id
    WHERE t.production_year >= 2000
    AND k.keyword LIKE '%Action%'
), RankedMovies AS (
    SELECT movie_title, production_year, movie_keyword, company_name, person_name, person_role,
           ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_year DESC) AS rank
    FROM MovieInfo
), AggregatedResults AS (
    SELECT production_year, 
           STRING_AGG(movie_title, ', ') AS movies_list,
           STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords, 
           STRING_AGG(DISTINCT company_name, ', ') AS companies,
           STRING_AGG(DISTINCT CONCAT(person_name, ' (', person_role, ')'), ', ') AS cast_details
    FROM RankedMovies
    GROUP BY production_year
)
SELECT * 
FROM AggregatedResults
ORDER BY production_year DESC;
