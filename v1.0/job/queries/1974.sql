WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
ActorFilmCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS film_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        person_id
    FROM 
        ActorFilmCounts
    WHERE 
        film_count >= (SELECT AVG(film_count) FROM ActorFilmCounts)
)
SELECT 
    a.name,
    at.title,
    at.production_year,
    COALESCE(m.keyword, 'No Keywords') AS keyword,
    ct.kind AS company_kind,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword m ON mk.keyword_id = m.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.person_id IN (SELECT person_id FROM TopActors)
    AND at.production_year >= 2000
    AND ct.kind IS NOT NULL
ORDER BY 
    at.production_year DESC, a.name;
