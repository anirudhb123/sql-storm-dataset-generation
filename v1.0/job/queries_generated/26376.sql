WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name ASC) AS aka_names,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name ASC) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords
    FROM 
        title m
    LEFT JOIN 
        aka_title ak ON m.id = ak.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
)
SELECT 
    md.movie_id, 
    md.title,
    md.production_year,
    k.kind AS movie_kind,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    kind_type k ON md.kind_id = k.id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
