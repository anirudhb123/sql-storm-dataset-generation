
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
FinalDetails AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keywords,
        md.company_types,
        cd.actor_count,
        cd.actor_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    *
FROM 
    FinalDetails
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, movie_title;
