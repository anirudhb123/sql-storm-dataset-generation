WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name p ON ci.person_id = p.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        a.title, a.production_year, c.name, p.name, r.role
),
RankedCompanies AS (
    SELECT 
        company_name,
        COUNT(DISTINCT movie_title) AS total_movies
    FROM 
        RankedMovies
    GROUP BY 
        company_name
    ORDER BY 
        total_movies DESC
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.company_name,
    rm.person_name,
    rm.person_role,
    rm.keyword_count,
    rc.total_movies
FROM 
    RankedMovies rm
JOIN 
    RankedCompanies rc ON rm.company_name = rc.company_name
WHERE 
    rm.keyword_count > 5
ORDER BY 
    rm.production_year DESC, rc.total_movies DESC;
