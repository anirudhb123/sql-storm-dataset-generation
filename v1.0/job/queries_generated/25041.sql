WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        c.kind AS company_type,
        COALESCE(STRING_AGG(DISTINCT ci.note, ', '), 'No Notes') AS notes
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
FullMovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.keywords,
        md.company_type,
        md.notes,
        COALESCE(
            (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id), 
            0
        ) AS info_count
    FROM 
        MovieDetails md
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actors,
    f.keywords,
    f.company_type,
    f.notes,
    f.info_count
FROM 
    FullMovieInfo f
WHERE 
    f.production_year BETWEEN 2000 AND 2023
ORDER BY 
    f.production_year DESC, f.title;
