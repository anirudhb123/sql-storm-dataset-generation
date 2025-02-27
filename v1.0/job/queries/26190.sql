WITH MovieInfo AS (
    SELECT 
        t.title,
        t.production_year,
        tk.keyword,
        c.name AS company_name,
        r.role,
        p.name AS person_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        company_name c ON c.id = (
            SELECT company_id 
            FROM movie_companies mc 
            WHERE mc.movie_id = t.id 
            LIMIT 1
        )
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        keyword,
        company_name,
        person_name,
        ROW_NUMBER() OVER(PARTITION BY keyword ORDER BY production_year DESC) AS rn
    FROM 
        MovieInfo
)
SELECT 
    title,
    production_year,
    keyword,
    company_name,
    person_name
FROM 
    RankedMovies
WHERE 
    rn <= 3
ORDER BY 
    keyword, production_year DESC;
