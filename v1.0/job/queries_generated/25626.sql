WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM
        aka_title t
    JOIN 
        title a ON t.movie_id = a.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year >= 2000
        AND a.title IS NOT NULL
),
TopAkaNames AS (
    SELECT 
        r.aka_name,
        COUNT(c.id) AS cast_count
    FROM 
        RankedTitles r
    JOIN 
        cast_info c ON r.aka_id = c.person_id
    WHERE 
        r.rank <= 5
    GROUP BY 
        r.aka_name
    ORDER BY 
        cast_count DESC
)
SELECT 
    t.title,
    t.production_year,
    a.aka_name,
    count(mk.keyword) AS keyword_count,
    string_agg(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    RankedTitles t
JOIN 
    TopAkaNames a ON t.aka_name = a.aka_name
LEFT JOIN 
    movie_keyword mk ON t.title_id = mk.movie_id
GROUP BY 
    t.title, t.production_year, a.aka_name
HAVING 
    count(mk.keyword) > 0
ORDER BY 
    t.production_year DESC, 
    keyword_count DESC;
