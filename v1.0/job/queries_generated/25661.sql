WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
MostPopularTitles AS (
    SELECT
        title_id,
        title,
        production_year,
        kind_id
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
PersonDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        p.info AS person_info,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON c.person_id = a.person_id
    JOIN 
        person_info p ON p.person_id = a.person_id
    WHERE 
        a.name ILIKE '%Smith%'
    GROUP BY 
        a.id, a.name, p.info
)
SELECT 
    p.name AS actor_name,
    p.person_info,
    m.title AS movie_title,
    m.production_year,
    COUNT(*) AS co_stars_count
FROM 
    PersonDetails p
JOIN 
    cast_info c ON c.person_id = p.aka_id
JOIN 
    MostPopularTitles m ON m.title_id = c.movie_id
GROUP BY 
    p.name, p.person_info, m.title, m.production_year
ORDER BY 
    co_stars_count DESC, m.production_year DESC;
