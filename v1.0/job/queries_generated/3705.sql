WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        num_cast_members
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
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
    COALESCE(mg.genre, 'Unknown') AS genre,
    COALESCE(ci.companies, 'No companies') AS production_companies,
    COALESCE(ci.company_types, 'No types') AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.title = mg.movie_id
LEFT JOIN 
    CompanyInfo ci ON tm.title = ci.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.num_cast_members DESC;
