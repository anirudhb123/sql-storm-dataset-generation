
WITH RankedMovies AS (
    SELECT 
        a.title AS MovieTitle,
        a.production_year AS ReleaseYear,
        k.keyword AS MovieKeyword,
        COUNT(c.id) AS CastCount,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY a.production_year DESC) AS RankByYear
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        MovieTitle,
        ReleaseYear,
        MovieKeyword,
        CastCount
    FROM 
        RankedMovies
    WHERE 
        RankByYear <= 5
)

SELECT 
    tm.MovieTitle,
    tm.ReleaseYear,
    tm.MovieKeyword,
    tm.CastCount,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS CompanyNames,
    LISTAGG(DISTINCT pi.info, ', ') WITHIN GROUP (ORDER BY pi.info) AS PersonInfo
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.MovieTitle = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON tm.MovieTitle = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
GROUP BY 
    tm.MovieTitle, tm.ReleaseYear, tm.MovieKeyword, tm.CastCount
ORDER BY 
    tm.ReleaseYear DESC, tm.MovieKeyword;
