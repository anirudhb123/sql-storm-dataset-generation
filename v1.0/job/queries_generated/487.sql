WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(p.age) AS max_age,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    CASE 
        WHEN a.name IS NULL THEN 'Unknown Actor'
        ELSE a.name 
    END AS actor_name
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT 
         p.id,
         EXTRACT(YEAR FROM AGE(NOW(), p.birthdate)) AS age 
     FROM 
         person_info p 
     WHERE 
         p.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')) p ON p.id = ci.person_id
LEFT JOIN 
    (SELECT 
         DISTINCT ca.person_id,
         ak.name 
     FROM 
         cast_info ca 
     JOIN 
         aka_name ak ON ca.person_id = ak.person_id) a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, a.name
ORDER BY 
    tm.production_year DESC, keyword_count DESC;
