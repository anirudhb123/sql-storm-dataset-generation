WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        c.nr_order,
        pn.name AS person_name,
        ci.kind AS person_role
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name pn ON ci.person_id = pn.person_id
    WHERE
        a.production_year >= 2000
    ORDER BY 
        a.production_year DESC,
        a.title
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        COUNT(DISTINCT person_name) AS cast_count,
        STRING_AGG(DISTINCT person_name, ', ') AS cast_names
    FROM 
        RankedMovies
    GROUP BY 
        title, production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        keywords,
        cast_count,
        cast_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    title,
    production_year,
    keywords,
    cast_count,
    cast_names
FROM 
    TopMovies
WHERE 
    rank <= 10;
