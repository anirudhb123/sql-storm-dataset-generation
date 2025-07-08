
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieGenres AS (
    SELECT 
        mk.movie_id,
        LISTAGG(kg.keyword, ', ') WITHIN GROUP (ORDER BY kg.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kg ON mk.keyword_id = kg.id
    GROUP BY 
        mk.movie_id
), 
MovieCompanies AS (
    SELECT 
        mc.id AS movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'Unknown') AS genres,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    rm.total_cast,
    rm.rank
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 5 OR rm.total_cast > 20
ORDER BY 
    rm.production_year DESC, 
    rm.rank ASC;
