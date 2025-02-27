
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_name a
    JOIN
        aka_title t ON a.id = t.id
    WHERE
        a.name LIKE '%the%'
),
StringProcessedTitles AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year,
        kind_id,
        LENGTH(movie_title) AS title_length,
        INITCAP(movie_title) AS processed_title
    FROM 
        RankedTitles
    WHERE 
        rank = 1
)
SELECT 
    s.aka_name,
    s.movie_title,
    s.production_year,
    kt.kind AS title_kind,
    c1.name AS company_name,
    c2.kind AS company_type,
    s.title_length
FROM 
    StringProcessedTitles s
JOIN 
    title t ON s.movie_title = t.title
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c1 ON mc.company_id = c1.id
JOIN 
    company_type c2 ON mc.company_type_id = c2.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    s.title_length > 20
GROUP BY 
    s.aka_name,
    s.movie_title,
    s.production_year,
    kt.kind,
    c1.name,
    c2.kind,
    s.title_length
ORDER BY 
    s.production_year DESC, 
    s.title_length DESC;
