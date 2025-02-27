WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title AS a
    JOIN 
        cast_info AS c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
LatestMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    m.title,
    m.production_year,
    coalesce(mk.keywords, 'No Keywords') AS keywords,
    p.name AS director_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT CASE WHEN ci.nr_order IS NULL THEN 1 END) AS unnumbered_roles
FROM 
    title AS m
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info AS ci ON m.id = ci.movie_id
LEFT JOIN 
    cast_info AS d ON m.id = d.movie_id AND d.person_role_id = (
        SELECT id FROM role_type WHERE role = 'Director'
    )
LEFT JOIN 
    aka_name AS p ON d.person_id = p.person_id
WHERE 
    (m.production_year > 2000 AND m.production_year < 2023)
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short')))
    AND (m.title IS NOT NULL AND m.title <> '')
    AND EXISTS (SELECT 1 FROM LatestMovies lm WHERE lm.title = m.title AND lm.production_year = m.production_year)
GROUP BY 
    m.title, m.production_year, mk.keywords, p.name
ORDER BY 
    m.production_year DESC, total_cast DESC;
