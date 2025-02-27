WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name n ON a.person_id = n.imdb_id
    JOIN 
        person_info pi ON n.imdb_id = pi.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    GROUP BY 
        t.id, a.name, p.gender
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT cc.kind) AS cast_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.gender,
    md.keywords,
    cd.company_name,
    cd.company_type,
    cd.cast_types
FROM 
    MovieDetails md
JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, md.title;
