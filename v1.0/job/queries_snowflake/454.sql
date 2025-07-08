
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
AverageProductionYears AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        aka_title
    WHERE 
        production_year IS NOT NULL
),
ExcludedYears AS (
    SELECT 
        production_year
    FROM 
        TopMovies
    WHERE 
        production_year < (SELECT avg_year FROM AverageProductionYears)
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    m.kind_id
FROM 
    aka_title m
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year NOT IN (SELECT production_year FROM ExcludedYears)
GROUP BY 
    m.id, m.title, m.production_year, cn.name, m.kind_id
HAVING 
    COUNT(DISTINCT mc.id) > 0
ORDER BY 
    m.production_year DESC, m.title;
