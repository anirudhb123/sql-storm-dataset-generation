WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
FilteredTitles AS (
    SELECT 
        aka_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),
AggregatedTitles AS (
    SELECT 
        aka_name, 
        COUNT(*) AS title_count,
        STRING_AGG(movie_title, ', ') AS titles
    FROM 
        FilteredTitles
    GROUP BY 
        aka_name
)
SELECT 
    a.aka_id,
    a.aka_name,
    a.title_count,
    a.titles,
    p.info AS person_info
FROM 
    AggregatedTitles a
LEFT JOIN 
    person_info p ON a.aka_name = (SELECT name FROM aka_name WHERE person_id = (SELECT person_id FROM cast_info WHERE movie_id IN (SELECT movie_id FROM aka_title WHERE title = a.aka_name) LIMIT 1))
ORDER BY 
    a.title_count DESC;
