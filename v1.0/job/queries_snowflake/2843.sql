
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cc.company_count, 0) AS number_of_companies,
    COUNT(DISTINCT l.linked_movie_id) AS linked_movie_count,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_link l ON tm.movie_id = l.movie_id
LEFT JOIN 
    CompanyCount cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    complete_cast cc2 ON tm.movie_id = cc2.movie_id
LEFT JOIN 
    cast_info ci ON cc2.subject_id = ci.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, cc.company_count
ORDER BY 
    tm.production_year DESC, number_of_companies DESC, linked_movie_count DESC;
