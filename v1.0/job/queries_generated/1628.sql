WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    JOIN complete_cast cc ON a.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    GROUP BY a.id, a.title, a.production_year
), 
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank <= 5
), 
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        m.note AS movie_note
    FROM movie_companies m
    JOIN company_name co ON m.company_id = co.id
    JOIN company_type ct ON m.company_type_id = ct.id
)

SELECT 
    TM.title,
    TM.production_year,
    TM.cast_count,
    COALESCE(CG.company_name, 'Independent') AS company_name,
    COALESCE(CG.company_type, 'N/A') AS company_type,
    TM.rank
FROM TopMovies TM
LEFT JOIN CompanyDetails CG ON TM.title = CG.movie_id
WHERE 
    TM.production_year >= 2000
ORDER BY TM.production_year, TM.rank;
