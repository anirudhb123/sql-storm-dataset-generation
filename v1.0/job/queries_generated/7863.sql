WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.gender
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.imdb_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    cd.actor_name,
    cd.gender,
    co.company_name,
    co.company_type,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    CastDetails cd ON md.movie_id = cd.movie_id
JOIN 
    CompanyDetails co ON md.movie_id = co.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, cd.actor_name, cd.gender, co.company_name, co.company_type
ORDER BY 
    md.production_year DESC, md.title;
