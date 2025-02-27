
WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT ka.name) AS num_cast,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ka.name) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%') 
    GROUP BY 
        a.title, t.production_year
),
TopRankedTitles AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5 
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    ci.note AS cast_note,
    rt.num_cast
FROM 
    TopRankedTitles tr
JOIN 
    title t ON tr.movie_title = t.title AND tr.production_year = t.production_year
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    RankedTitles rt ON tr.movie_title = rt.movie_title AND tr.production_year = rt.production_year
ORDER BY 
    t.production_year DESC, 
    rt.num_cast DESC, 
    t.title;
