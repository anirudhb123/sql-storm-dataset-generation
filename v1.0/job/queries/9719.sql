WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.cast_names,
        ROW_NUMBER() OVER (PARTITION BY md.keyword ORDER BY md.production_year DESC) AS rn
    FROM 
        MovieDetails md
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_names
FROM 
    FilteredMovies
WHERE 
    rn = 1
ORDER BY 
    production_year DESC;
