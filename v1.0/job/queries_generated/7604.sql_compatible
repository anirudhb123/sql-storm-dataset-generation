
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        c.kind AS company_type,
        a.name AS actor_name
    FROM 
        aka_title t
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
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.kind, a.name
),
GenreCount AS (
    SELECT 
        d.movie_id,
        COUNT(DISTINCT d.keywords) AS keyword_count,
        COUNT(DISTINCT d.actor_name) AS actor_count
    FROM 
        MovieDetails d
    GROUP BY 
        d.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    gc.keyword_count,
    gc.actor_count
FROM 
    MovieDetails md
JOIN 
    GenreCount gc ON md.movie_id = gc.movie_id
ORDER BY 
    md.production_year DESC, gc.actor_count DESC;
