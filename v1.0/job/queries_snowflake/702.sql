
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
CASTINGS AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ct.cast_count > 10 THEN 'Large Cast'
        WHEN ct.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords mk ON rt.aka_id = mk.movie_id
LEFT JOIN 
    CASTINGS ct ON rt.aka_id = ct.movie_id
WHERE 
    rt.rn = 1
AND 
    rt.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rt.production_year DESC, 
    rt.aka_name;
