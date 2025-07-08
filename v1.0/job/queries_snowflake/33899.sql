
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_cast_members
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CompanyMovieDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    cmd.companies,
    cmd.company_types,
    CASE 
        WHEN tm.num_cast_members > 10 THEN 'Large Cast'
        WHEN tm.num_cast_members BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_categories
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieDetails cmd ON tm.movie_id = cmd.movie_id
WHERE 
    cmd.companies IS NOT NULL
ORDER BY 
    tm.production_year DESC,
    tm.num_cast_members DESC;
