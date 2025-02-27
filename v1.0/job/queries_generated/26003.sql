WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.company_name) AS company_names,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names
    FROM 
        title t
    LEFT JOIN
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name akn ON ci.person_id = akn.person_id
    LEFT JOIN 
        name p ON ci.person_id = p.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        keywords,
        company_names,
        cast_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS row_num
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    company_names,
    cast_names
FROM 
    FilteredMovies
WHERE 
    row_num <= 10
ORDER BY 
    production_year ASC, movie_title ASC;
