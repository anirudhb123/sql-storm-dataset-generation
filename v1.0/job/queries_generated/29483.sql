WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name p ON ci.person_id = p.imdb_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
),
AggregateMovieInfo AS (
    SELECT 
        md.movie_title,
        md.production_year,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies,
        STRING_AGG(DISTINCT md.person_name || ' (' || md.person_role || ')', ', ') AS cast_information
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_title, md.production_year
)
SELECT 
    ami.movie_title,
    ami.production_year,
    ami.keywords,
    ami.companies,
    ami.cast_information
FROM 
    AggregateMovieInfo ami
ORDER BY 
    ami.production_year DESC, ami.movie_title;
