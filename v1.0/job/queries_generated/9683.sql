WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM aka_title a
    JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id 
    GROUP BY a.id, a.title, a.production_year, a.kind_id
),
CommonInfo AS (
    SELECT 
        m.id AS movie_id,
        GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY m.id, c.name, ct.kind
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    ci.keywords,
    ci.company_name,
    ci.company_type
FROM RankedMovies rm
JOIN CommonInfo ci ON rm.id = ci.movie_id
WHERE rm.production_year >= 2000
ORDER BY rm.total_cast DESC, rm.movie_title ASC
LIMIT 50;
