WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(c.name, 'Unknown') AS company_name,
        ARRAY_AGG(DISTINCT a.name) AS aliases,
        ARRAY_AGG(DISTINCT p.info) AS person_info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_name,
        md.aliases,
        md.person_info
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
        AND ARRAY_LENGTH(md.keywords, 1) > 1
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    ARRAY_TO_STRING(fm.keywords, ', ') AS keywords_list,
    ARRAY_TO_STRING(fm.aliases, ', ') AS alias_list,
    ARRAY_TO_STRING(fm.person_info, '; ') AS person_details
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.title;
