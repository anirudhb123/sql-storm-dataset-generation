WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        rt.total_cast
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_year <= 10 
        AND rt.total_cast > 5
)
SELECT 
    f.movie_title,
    f.production_year,
    COALESCE(NULLIF(f.total_cast, 0), 'No Cast Available') AS total_cast_info,
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS associated_keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    complete_cast cc2 ON f.movie_title = (SELECT title FROM aka_title WHERE id = cc2.movie_id)
LEFT JOIN 
    cast_info c2 ON cc2.subject_id = c2.id
LEFT JOIN 
    aka_name ak ON c2.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON f.production_year = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    f.movie_title, f.production_year, f.total_cast, ak.name
HAVING 
    COUNT(DISTINCT k.keyword) > 0
ORDER BY 
    f.production_year DESC;
