
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT d.name, ',') WITHIN GROUP (ORDER BY d.name) AS directors,
        LISTAGG(DISTINCT k.keyword, ',') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id AND it.info = 'Director'
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name d ON ci.person_id = d.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FullCast AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT a.name, ',') WITHIN GROUP (ORDER BY a.name) AS full_cast
    FROM 
        MovieDetails m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        m.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.directors,
        fc.full_cast,
        md.keywords
    FROM 
        MovieDetails md
    JOIN 
        FullCast fc ON md.movie_id = fc.movie_id
    ORDER BY 
        md.production_year DESC
)
SELECT 
    movie_id,
    title,
    production_year,
    directors,
    full_cast,
    keywords
FROM 
    FinalBenchmark
WHERE 
    full_cast IS NOT NULL
LIMIT 100;
