WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        SUM(CASE WHEN ik.id IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ik ON mk.keyword_id = ik.id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count,
        actors,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY company_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    title,
    production_year,
    company_count,
    actors,
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 10;
