WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY count(c.id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rank = 1
)

SELECT 
    tm.title, 
    tm.production_year, 
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC;
