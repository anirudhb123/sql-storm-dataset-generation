WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rt.role,
        cni.name AS company_name,
        mk.keyword AS movie_keyword,
        COALESCE(mi.info, 'No Additional Info') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    LEFT JOIN 
        company_name cni ON mc.company_id = cni.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    LEFT JOIN 
        role_type rt ON rt.id = (SELECT DISTINCT role_id FROM cast_info WHERE movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1) LIMIT 1)
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT id FROM title WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    ORDER BY 
        rm.production_year DESC, 
        rm.total_cast DESC
)
SELECT 
    movie_title,
    production_year,
    total_cast,
    aka_names,
    GROUP_CONCAT(DISTINCT company_name ORDER BY company_name) AS companies,
    GROUP_CONCAT(DISTINCT movie_keyword ORDER BY movie_keyword) AS keywords,
    STRING_AGG(DISTINCT additional_info, '; ') AS info_summary
FROM 
    MovieDetails
GROUP BY 
    movie_title, 
    production_year, 
    total_cast, 
    aka_names
ORDER BY 
    production_year DESC, 
    total_cast DESC;
