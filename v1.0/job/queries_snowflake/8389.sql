WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        RANK() OVER (ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.company_count, 
        rm.companies 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title, 
    tm.production_year, 
    ak.name AS actor_name, 
    rt.role, 
    kc.keyword
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
