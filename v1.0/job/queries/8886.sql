WITH RankedFilms AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
TopTitles AS (
    SELECT 
        rf.title_id,
        rf.title,
        rf.production_year,
        rf.keyword
    FROM 
        RankedFilms rf
    WHERE 
        rf.rank = 1
)
SELECT 
    tt.title,
    a.name AS actor_name,
    c.kind AS company_type,
    mi.info AS movie_info
FROM 
    TopTitles tt
JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON tt.title_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON tt.title_id = mi.movie_id AND mi.info_type_id = 1
WHERE 
    tt.production_year = 2022
ORDER BY 
    tt.title, a.name;
