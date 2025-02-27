WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS person_name,
        a.name AS aka_name
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
AkaAggregates AS (
    SELECT 
        aka_name, 
        COUNT(DISTINCT title_id) AS title_count,
        ARRAY_AGG(DISTINCT title ORDER BY title) AS titles 
    FROM 
        MovieDetails
    GROUP BY 
        aka_name
),
FinalResults AS (
    SELECT 
        ON.title_count, 
        ON.aka_name, 
        ON.titles,
        COUNT(DISTINCT ON.title_id) AS unique_movies
    FROM 
        AkaAggregates ON
    JOIN 
        MovieDetails MD ON ON.aka_name = MD.aka_name
    GROUP BY 
        ON.aka_name, ON.title_count, ON.titles
)
SELECT 
    aka_name, 
    title_count, 
    unique_movies, 
    titles
FROM 
    FinalResults 
ORDER BY 
    unique_movies DESC
LIMIT 10;
