WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY a.name) AS rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopRankedMovies AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year,
        movie_keyword
    FROM 
        RankedMovies
    WHERE 
        rank = 1
)
SELECT 
    t.movie_title,
    COUNT(tc.id) AS total_cast,
    LISTAGG(DISTINCT c.name, ', ') AS cast_members,
    STRING_AGG(CONCAT_WS(' - ', co.name, ct.kind), '; ') AS companies_involved,
    STRING_AGG(DISTINCT p.info, ', ') AS additional_info
FROM 
    TopRankedMovies t
LEFT JOIN 
    complete_cast cc ON t.aka_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
LEFT JOIN 
    name n ON ci.person_id = n.id
LEFT JOIN 
    movie_companies mc ON t.aka_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON t.aka_id = mi.movie_id
LEFT JOIN 
    info_type p ON mi.info_type_id = p.id
GROUP BY 
    t.movie_title
ORDER BY 
    total_cast DESC
LIMIT 10;
