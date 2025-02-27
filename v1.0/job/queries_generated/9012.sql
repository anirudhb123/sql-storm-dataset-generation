WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.kind AS company_type,
        p.info AS person_info,
        COUNT(k.keyword) AS keyword_count
    FROM 
        aka_title a 
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        person_info p ON ci.person_id = p.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, c.kind, p.info
), MovieRanks AS (
    SELECT 
        title, 
        production_year, 
        company_type, 
        person_info, 
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    title, 
    production_year, 
    company_type, 
    person_info, 
    keyword_count 
FROM 
    MovieRanks
WHERE 
    rank <= 10 
ORDER BY 
    production_year DESC, rank;
