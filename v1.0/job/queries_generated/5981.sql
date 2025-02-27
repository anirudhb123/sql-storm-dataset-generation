WITH RecursiveData AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        c.nr_order AS cast_order,
        c.note AS cast_note,
        co.name AS company_name,
        mi.info AS movie_info
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND c.nr_order IS NOT NULL
), RankedData AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        cast_order,
        CAST(cast_order AS INTEGER) + ROW_NUMBER() OVER (PARTITION BY movie_title ORDER BY cast_order) AS adjusted_order,
        cast_note,
        company_name,
        movie_info,
        ROW_NUMBER() OVER (PARTITION BY movie_title ORDER BY cast_order) AS rank
    FROM 
        RecursiveData
)
SELECT 
    aka_id,
    aka_name,
    movie_title,
    cast_order,
    adjusted_order,
    cast_note,
    company_name,
    movie_info
FROM 
    RankedData
WHERE 
    rank <= 5
ORDER BY 
    movie_title, adjusted_order;
