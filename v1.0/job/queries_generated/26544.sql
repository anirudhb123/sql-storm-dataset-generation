WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS person_name,
        ak.id AS aka_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kw.id) AS keyword_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, ak.name, ak.id
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY production_year DESC, company_count DESC, keyword_count DESC) AS rank
    FROM 
        MovieData
)
SELECT 
    movie_id,
    title,
    production_year,
    person_name,
    company_count,
    keyword_count,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, company_count DESC;
