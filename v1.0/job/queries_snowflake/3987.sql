
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    t.title,
    t.production_year,
    LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
    (SELECT COUNT(DISTINCT c.id) 
     FROM cast_info c 
     WHERE c.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)) AS actor_count,
    (SELECT 
         LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) 
     FROM 
         movie_keyword mk 
     JOIN 
         keyword k ON mk.keyword_id = k.id 
     WHERE 
         mk.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)) AS keywords
FROM 
    TopMovies t
JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
GROUP BY 
    t.title, t.production_year
ORDER BY 
    t.production_year DESC, t.title ASC;
