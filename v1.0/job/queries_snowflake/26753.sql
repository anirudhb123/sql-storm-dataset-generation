
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank 
    FROM 
        aka_title t 
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    ORDER BY 
        t.production_year DESC
),
MovieList AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(c.id) AS cast_count 
    FROM 
        title m 
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id 
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id 
    WHERE 
        m.production_year >= 2000 
    GROUP BY 
        m.id, m.title, m.production_year 
    HAVING 
        COUNT(c.id) > 5 
)
SELECT 
    ak.name AS aka_name, 
    m.title, 
    m.production_year, 
    r.title_rank, 
    c.role_id, 
    kk.keyword 
FROM 
    RankedTitles r 
JOIN 
    MovieList m ON r.title = m.title 
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id 
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id 
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id 
LEFT JOIN 
    keyword kk ON mk.keyword_id = kk.id 
WHERE 
    ak.name IS NOT NULL 
ORDER BY 
    m.production_year DESC, 
    r.title_rank, 
    ak.name;
