WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT an.name) AS actor_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id
),
Top10Movies AS (
    SELECT 
        movie_id, 
        title,
        production_year, 
        cast_count,
        actor_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    m.actor_names,
    m.keywords,
    c.kind AS company_type,
    cn.name AS company_name
FROM 
    Top10Movies m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
ORDER BY 
    m.rank;
