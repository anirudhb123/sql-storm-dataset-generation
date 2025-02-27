
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_type AS c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        t.production_year DESC
),
BenchmarkResults AS (
    SELECT 
        md.movie_title, 
        md.production_year, 
        md.actor_names, 
        md.keywords, 
        md.company_types,
        CASE 
            WHEN md.production_year > 2020 THEN 'Recent'
            WHEN md.production_year >= 2010 THEN 'Modern'
            ELSE 'Classic'
        END AS era
    FROM 
        MovieDetails AS md
)
SELECT 
    era, 
    COUNT(*) AS total_movies, 
    STRING_AGG(movie_title, ', ') AS movies_list,
    STRING_AGG(actor_names, '; ') AS actors_list,
    STRING_AGG(keywords, '; ') AS keywords_list,
    STRING_AGG(company_types, '; ') AS companies_list
FROM 
    BenchmarkResults
GROUP BY 
    era
ORDER BY 
    total_movies DESC;
