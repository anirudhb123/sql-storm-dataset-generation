WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
), 
KeywordCTE AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keyword_count, 0) AS keyword_count,
        m.cast_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        KeywordCTE kw ON m.movie_id = kw.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.cast_count
FROM 
    MovieDetails md
WHERE 
    md cast_count >= 5
AND 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 50;

-- Additional Query to Test Performance with NULL Logic and Joins
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    co.id IS NULL -- Retrieve actors in movies without associated companies
OR 
    co.country_code NOT LIKE 'US'
ORDER BY 
    a.name, 
    t.title;
