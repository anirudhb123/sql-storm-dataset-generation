
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN m.production_year IS NOT NULL THEN DATE_PART(YEAR, '2024-10-01'::DATE) - m.production_year ELSE NULL END) AS avg_age,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT cmp.name, ', ') WITHIN GROUP (ORDER BY cmp.name) AS companies
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cmp ON mc.company_id = cmp.id
    GROUP BY 
        m.id, m.title
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        total_cast, 
        avg_age, 
        keywords, 
        companies,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.total_cast,
    tm.avg_age,
    tm.keywords,
    tm.companies
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.total_cast DESC;
