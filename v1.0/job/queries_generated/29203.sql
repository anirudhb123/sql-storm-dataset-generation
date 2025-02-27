WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.company_name AS production_company
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, c.company_name
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast c
    JOIN 
        cast_info ci ON c.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FinalReport AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.production_company,
        cd.total_cast,
        cd.cast_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    keywords, 
    production_company, 
    total_cast, 
    cast_names
FROM 
    FinalReport
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    title;
