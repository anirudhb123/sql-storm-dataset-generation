
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS row_num
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
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
        alias_names,
        company_names,
        keywords
    FROM 
        MovieDetails
    WHERE 
        row_num = 1
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.alias_names,
    tm.company_names,
    tm.keywords,
    pi.info AS person_info
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    pi.info_type_id = (
        SELECT id 
        FROM info_type 
        WHERE info = 'Biography'
    )
ORDER BY 
    tm.production_year DESC, tm.title;
