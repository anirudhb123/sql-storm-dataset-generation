
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieGenres AS (
    SELECT 
        t.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actor_names,
        COALESCE(mg.genre, 'Unknown') AS genre
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id
    WHERE 
        rm.rank_within_year <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mt.kind) AS unique_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type mt ON mc.company_type_id = mt.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actor_names,
    tm.genre,
    COALESCE(cd.companies_involved, 'No companies involved') AS companies_involved,
    COALESCE(cd.unique_company_types, 0) AS unique_company_types,
    CASE 
        WHEN tm.total_cast IS NULL OR tm.total_cast = 0 THEN 'No cast information'
        ELSE 'Has cast information'
    END AS cast_information_indicator
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
