
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DirectorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role = 'director'
    GROUP BY 
        c.movie_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(d.director_count, 0) AS director_count,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN m.title_rank = 1 THEN 'First Title of Year'
        ELSE 'Other Title'
    END AS title_category
FROM 
    RankedMovies m
LEFT JOIN 
    DirectorRoles d ON m.movie_id = d.movie_id
LEFT JOIN 
    KeywordMovies k ON m.movie_id = k.movie_id
WHERE 
    (d.director_count < 3 OR d.director_count IS NULL)
    AND m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    m.title;
