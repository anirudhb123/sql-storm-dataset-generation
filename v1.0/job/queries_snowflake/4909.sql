
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
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
        t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS before_2000_count
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.aka_name,
    rt.title,
    rt.production_year,
    ms.total_cast,
    ms.before_2000_count,
    ci.company_count,
    ci.company_names
FROM 
    RankedTitles rt
JOIN 
    MovieStats ms ON rt.aka_id = ms.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.aka_id = ci.movie_id
WHERE 
    rt.rank = 1
    AND ms.total_cast > 0
ORDER BY 
    rt.production_year DESC, 
    rt.aka_name
LIMIT 100;
