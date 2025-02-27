WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
TopKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
CastAndCrew AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast,
        c.note AS company_name,
        i.info AS movie_info
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON m.id = ci.movie_id
    LEFT JOIN 
        role_type AS r ON ci.role_id = r.id
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info AS i ON m.id = i.movie_id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        m.id, c.note, i.info
)
SELECT 
    m.title,
    m.production_year,
    k.keywords,
    c.cast,
    c.company_name,
    c.movie_info 
FROM 
    aka_title AS m
JOIN 
    TopKeywords AS k ON m.id = k.movie_id
JOIN 
    CastAndCrew AS c ON m.id = c.movie_id
WHERE 
    m.production_year BETWEEN 2010 AND 2020
ORDER BY 
    m.production_year DESC, m.title ASC;
