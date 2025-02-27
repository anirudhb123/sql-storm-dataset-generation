WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.info AS person_info,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        person_info p ON cc.subject_id = p.person_id
    JOIN 
        title m ON m.id = a.id
    WHERE 
        a.production_year >= 2000
    AND 
        p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award Winner')
)
SELECT 
    movie_title,
    movie_keyword,
    company_name,
    person_info
FROM 
    RankedMovies
WHERE 
    rank = 1
ORDER BY 
    movie_title;
