
WITH Dataset AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        c.note AS cast_note,
        p.info AS person_info,
        k.keyword AS movie_keyword
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND (a.name LIKE '%Smith%' OR t.title LIKE '%Smith%')
),
AggregatedData AS (
    SELECT 
        aka_name,
        movie_title,
        production_year,
        COUNT(DISTINCT aka_id) AS aka_count,
        LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords
    FROM 
        Dataset
    GROUP BY 
        aka_name, movie_title, production_year
)
SELECT 
    aka_name,
    movie_title,
    production_year,
    aka_count,
    keywords
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, aka_count DESC;
