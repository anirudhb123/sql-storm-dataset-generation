WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        m1.name AS main_company,
        m2.name AS secondary_company,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title a
    LEFT JOIN
        movie_companies mc ON a.movie_id = mc.movie_id
    LEFT JOIN
        company_name m1 ON mc.company_id = m1.id AND mc.company_type_id = 1
    LEFT JOIN
        company_name m2 ON mc.company_id = m2.id AND mc.company_type_id = 2
    LEFT JOIN
        complete_cast cc ON a.movie_id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        a.id, a.title, a.production_year, a.kind_id, m1.name, m2.name
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) as movie_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.main_company,
    tm.secondary_company,
    tm.cast_count,
    tm.aka_names
FROM 
    TopMovies tm
WHERE 
    movie_rank <= 10
ORDER BY 
    tm.cast_count DESC, tm.title;
