WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT ca.name) AS cast_names,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopKeywords AS (
    SELECT movie_id, keyword_count
    FROM RankedMovies
    WHERE rn <= 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    STRING_AGG(DISTINCT rm.cast_names::text, ', ') AS full_cast,
    STRING_AGG(DISTINCT rm.company_names::text, ', ') AS production_companies
FROM 
    RankedMovies rm
JOIN 
    TopKeywords tk ON rm.movie_id = tk.movie_id
GROUP BY 
    rm.title, rm.production_year, rm.keyword_count
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;
