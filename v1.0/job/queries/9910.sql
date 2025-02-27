
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        company_names,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    m.company_names,
    m.keywords,
    p.info
FROM 
    TopMovies m
JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    person_info p ON p.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = m.movie_id)
WHERE 
    m.rank <= 10 AND 
    it.info = 'Awards'
ORDER BY 
    m.production_year DESC;
