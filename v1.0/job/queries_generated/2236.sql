WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        com.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name com ON mc.company_id = com.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.movie_id, com.name, ct.kind
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    COALESCE(md.production_year, '-') AS production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    COALESCE(md.actor_names, 'Unknown') AS actor_names,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(kd.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
