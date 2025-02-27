WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),

CastInfo AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT n.name ORDER BY n.name) AS cast_names,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    GROUP BY 
        c.movie_id
),

FinalBenchmark AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.aka_names,
        c.cast_names,
        c.total_cast_members,
        LENGTH(m.aka_names) AS aka_length,
        LENGTH(c.cast_names) AS cast_length
    FROM 
        MovieInfo m
    LEFT JOIN 
        CastInfo c ON m.movie_id = c.movie_id
)

SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    cast_names,
    total_cast_members,
    aka_length,
    cast_length
FROM 
    FinalBenchmark
WHERE 
    production_year >= 2000
ORDER BY 
    total_cast_members DESC, production_year DESC
LIMIT 50;
