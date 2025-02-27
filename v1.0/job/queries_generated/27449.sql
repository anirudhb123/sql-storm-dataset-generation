WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT m2.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopRankedMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        movie_keyword 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
FROM 
    TopRankedMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    tm.movie_title, 
    tm.production_year
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
