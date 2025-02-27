WITH MovieData AS (
    SELECT 
        t.title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
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
        movie_companies mco ON t.id = mco.movie_id
    JOIN 
        company_name c ON mco.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        title, 
        production_year, 
        keywords, 
        companies,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC, production_year ASC) AS rank
    FROM 
        MovieData
)
SELECT 
    title, 
    production_year, 
    keywords, 
    companies, 
    cast_count 
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
