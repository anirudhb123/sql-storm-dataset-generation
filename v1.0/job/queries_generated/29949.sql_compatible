
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
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
        t.id, t.title, t.production_year
),
MovieRoleDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(r.role, ', ') AS roles,
        STRING_AGG(DISTINCT p.name, ', ') AS actors
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.person_role_id = r.id
    LEFT JOIN 
        name p ON ci.person_id = p.imdb_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    mrd.roles,
    mrd.actors,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = md.movie_id) AS cast_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id) AS info_count
FROM 
    MovieDetails md
LEFT JOIN 
    MovieRoleDetails mrd ON md.movie_id = mrd.movie_id
ORDER BY 
    md.production_year DESC, md.title;
