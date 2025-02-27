WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2022  
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        MovieData
)
SELECT 
    movie_id,
    title,
    production_year,
    company_type,
    total_cast,
    cast_names,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10  
ORDER BY 
    production_year DESC;