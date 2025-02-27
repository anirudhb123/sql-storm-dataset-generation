
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(CONCAT(a.name, ' (', r.role, ')'), ', ' ORDER BY ci.nr_order) AS cast_details
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000 AND 
        k.keyword LIKE '%Action%'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    HAVING 
        COUNT(DISTINCT a.id) >= 3
),
CompanyMovieDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        COUNT(mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names
    FROM 
        MovieDetails md
    JOIN 
        movie_companies mc ON md.movie_title = (SELECT title FROM title WHERE title = md.movie_title LIMIT 1)
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        md.movie_title, md.production_year
)
SELECT 
    cmd.movie_title,
    cmd.production_year,
    cmd.total_companies,
    cmd.company_names,
    md.cast_details
FROM 
    CompanyMovieDetails cmd
JOIN 
    MovieDetails md ON cmd.movie_title = md.movie_title AND cmd.production_year = md.production_year
ORDER BY 
    cmd.production_year DESC, cmd.movie_title;
