WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.imdb_index AS movie_imdb_index,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON at.id = ak.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, t.imdb_index
),
CastDetails AS (
    SELECT 
        t.id AS movie_id,
        GROUP_CONCAT(DISTINCT p.name ORDER BY co.nr_order) AS cast_names,
        GROUP_CONCAT(DISTINCT rt.role ORDER BY co.nr_order) AS roles
    FROM 
        title t
    LEFT JOIN 
        cast_info co ON t.id = co.movie_id
    LEFT JOIN 
        aka_name p ON co.person_id = p.person_id
    LEFT JOIN 
        role_type rt ON co.role_id = rt.id
    GROUP BY 
        t.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_imdb_index,
    md.aka_names,
    cd.cast_names,
    cd.roles,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    CastDetails cd ON md.movie_imdb_index = cd.movie_id
WHERE 
    md.production_year > 2000 
    AND COUNT(cd.cast_names) > 2
ORDER BY 
    md.production_year DESC;
