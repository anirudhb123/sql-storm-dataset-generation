WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        companies,
        keywords,
        RANK() OVER (ORDER BY company_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.companies,
    tm.keywords,
    GROUP_CONCAT(DISTINCT an.name) AS actors,
    GROUP_CONCAT(DISTINCT rt.role) AS roles
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    tm.rank <= 10 
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.company_count, tm.companies, tm.keywords
ORDER BY 
    tm.rank;

This query benchmarks string processing by aggregating company names, keywords, and actor roles in a structured manner, utilizing Common Table Expressions (CTEs) for clarity and performance. The focus is on the top 10 movies based on the number of associated companies.
