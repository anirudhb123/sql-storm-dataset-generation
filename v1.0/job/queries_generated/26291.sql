WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS company_names,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        keywords, 
        company_names, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    f.title,
    f.production_year,
    STRING_AGG(DISTINCT fk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT fn.name, ', ') AS cast_members,
    f.cast_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info ci ON f.title IN (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name fn ON ci.person_id = fn.person_id
LEFT JOIN 
    movie_companies mc ON f.title IN (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    f.title, f.production_year, f.cast_count
ORDER BY 
    f.production_year DESC;
