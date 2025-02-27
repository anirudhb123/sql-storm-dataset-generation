WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopCast AS (
    SELECT 
        t.id AS title_id,
        GROUP_CONCAT(DISTINCT a.name) AS cast_names
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order < 5  -- Only top 5 cast members
    GROUP BY 
        t.id
),
FinalOutput AS (
    SELECT 
        md.movie_title,
        md.production_year,
        tc.cast_names,
        md.companies,
        md.keywords
    FROM 
        MovieDetails md
    JOIN 
        TopCast tc ON md.movie_title = tc.title_id
)
SELECT 
    movie_title,
    production_year,
    cast_names,
    companies,
    keywords
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, movie_title;
