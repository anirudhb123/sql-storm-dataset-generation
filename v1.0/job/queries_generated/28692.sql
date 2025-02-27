WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.person_id) AS cast_ids, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title m ON a.movie_id = m.id
    LEFT JOIN 
        cast_info c ON c.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        a.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        aka_id,
        title,
        production_year,
        cast_ids,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    t.title,
    t.production_year,
    t.cast_ids,
    t.keywords,
    cn.name AS company_name,
    rt.role
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.aka_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    role_type rt ON rt.id IN (SELECT DISTINCT ci.person_role_id FROM cast_info ci WHERE ci.movie_id = t.aka_id)
ORDER BY 
    t.production_year DESC, t.title;
