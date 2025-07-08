
WITH RankedMovies AS (
    SELECT 
        ak.title AS ak_title,
        ak.production_year,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title ak
    JOIN movie_companies mc ON ak.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN cast_info ci ON ak.id = ci.movie_id
    WHERE ak.production_year >= 2000 
      AND ak.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY ak.id, ak.title, ak.production_year, ct.kind
),
TopRankedMovies AS (
    SELECT ak_title, production_year, company_type, total_cast, company_names
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    ak_title,
    production_year,
    company_type,
    total_cast,
    company_names,
    'Produced in ' || production_year || ' with ' || total_cast || ' cast members' AS description
FROM TopRankedMovies
ORDER BY production_year DESC, total_cast DESC;
