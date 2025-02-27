
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),

RankedAkaNames AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        RankedMovies m ON m.movie_id = cc.movie_id
    GROUP BY 
        ak.name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)

SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.aka_names,
    m.keywords,
    STRING_AGG(DISTINCT an.name, ', ') AS top_aka_names
FROM 
    RankedMovies m
LEFT JOIN 
    RankedAkaNames an ON an.movie_count >= 1
GROUP BY 
    m.movie_id, m.title, m.production_year, m.cast_count, m.aka_names, m.keywords
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
