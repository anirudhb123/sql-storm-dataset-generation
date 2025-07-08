WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(m_info.info_type_id) AS avg_info_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_info m_info ON t.id = m_info.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.avg_info_type
    FROM 
        RankedMovies r
    WHERE 
        r.rn <= 5
)
SELECT 
    t.title,
    k.keyword,
    c.name AS company_name,
    ci.kind AS company_type,
    t.production_year
FROM 
    TopRatedMovies t
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ci ON mc.company_type_id = ci.id
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
