WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    title,
    production_year,
    aka_names,
    keywords,
    cast_count,
    company_count
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    cast_count DESC, production_year DESC;
