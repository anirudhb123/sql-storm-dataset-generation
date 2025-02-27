WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id || ':' || p.name) AS cast_info,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cp.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name p ON p.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type cp ON cp.id = mc.company_type_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_info,
        keywords,
        company_types,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_info,
    keywords,
    company_types
FROM 
    TopMovies
WHERE 
    rn <= 10;
