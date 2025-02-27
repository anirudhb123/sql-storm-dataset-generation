WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(ci.id) AS total_cast_members,
        ARRAY_AGG(DISTINCT ak.name) AS alias_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast_members,
        alias_names,
        RANK() OVER (ORDER BY total_cast_members DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast_members,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.total_cast_members
ORDER BY 
    tm.rank;
