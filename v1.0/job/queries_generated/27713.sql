WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast_members,
        rm.actor_names,
        rm.keywords,
        mc.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    cmi.title,
    cmi.production_year,
    cmi.total_cast_members,
    cmi.actor_names,
    cmi.keywords,
    cmi.companies
FROM 
    CompleteMovieInfo cmi
WHERE 
    cmi.total_cast_members > 5
ORDER BY 
    cmi.production_year DESC, 
    cmi.total_cast_members DESC;
