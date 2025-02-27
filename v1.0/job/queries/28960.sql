
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies
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
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, t.imdb_index
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN rt.role = 'actor' THEN 1 ELSE 0 END) AS actor_count,
        SUM(CASE WHEN rt.role = 'actress' THEN 1 ELSE 0 END) AS actress_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id
),
CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        cd.total_cast,
        cd.actor_count,
        cd.actress_count
    FROM 
        MovieDetails md
    JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.keywords,
    cd.companies,
    cd.total_cast,
    cd.actor_count,
    cd.actress_count
FROM 
    CombinedDetails cd
WHERE 
    cd.production_year BETWEEN 1990 AND 2000
ORDER BY 
    cd.production_year DESC, 
    cd.actor_count DESC, 
    cd.title ASC;
