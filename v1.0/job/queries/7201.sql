WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tr.movie_title,
    tr.production_year,
    ak.name AS actor_name,
    k.keyword AS keyword
FROM 
    TopRankedMovies AS tr
JOIN 
    complete_cast AS cc ON tr.movie_id = cc.movie_id
JOIN 
    cast_info AS c ON cc.subject_id = c.id
JOIN 
    aka_name AS ak ON c.person_id = ak.person_id
JOIN 
    movie_keyword AS mk ON tr.movie_id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
ORDER BY 
    tr.production_year, tr.movie_title, ak.name;
