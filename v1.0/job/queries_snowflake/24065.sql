
WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.movie_id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
), 
CompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    rk.actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ci.companies, 'No Companies') AS companies,
    COALESCE(ci.company_types, 'No Company Types')
FROM 
    TopMovies tm
JOIN 
    RankedMovies rk ON tm.title = rk.title AND tm.production_year = rk.production_year
LEFT JOIN 
    MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id LIMIT 1)
LEFT JOIN 
    CompanyInfo ci ON tm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id LIMIT 1)
WHERE 
    rk.actor_count IS NOT NULL
ORDER BY 
    tm.production_year DESC, rk.actor_count DESC;
