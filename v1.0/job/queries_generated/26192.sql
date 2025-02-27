WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT(an.name, ' as ', rt.role), ', ') AS cast
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    pr.cast
FROM 
    MovieDetails md
LEFT JOIN 
    PersonRoles pr ON md.title_id = pr.movie_id
ORDER BY 
    md.production_year DESC, md.title;

This SQL query first builds two common table expressions (CTEs): 
1. `MovieDetails` which aggregates movie information including keywords and associated companies for each movie produced in or after the year 2000. 
2. `PersonRoles` which aggregates the cast information and their roles for each movie.

Finally, it joins these two CTEs to produce a coherent list of movies with their respective details, cast, and keywords, ordered by production year and movie title.
