
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL 
)
SELECT 
    r.aka_name,
    COUNT(DISTINCT r.title_id) AS title_count,
    LISTAGG(DISTINCT r.title, ', ') WITHIN GROUP (ORDER BY r.title) AS titles,
    MIN(r.production_year) AS earliest_year,
    MAX(r.production_year) AS latest_year
FROM 
    RankedTitles r
WHERE 
    r.rank <= 5
GROUP BY 
    r.aka_name
ORDER BY 
    title_count DESC, earliest_year ASC;
