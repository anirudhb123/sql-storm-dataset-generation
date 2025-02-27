WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        name p ON ci.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, cn.id, ct.id
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.company_name,
        md.company_type,
        md.keywords,
        md.aka_names,
        md.cast_names,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        MovieDetails md
    JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year, md.company_name, md.company_type, md.keywords, md.aka_names, md.cast_names
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    company_name,
    company_type,
    keywords,
    aka_names,
    cast_names,
    total_keywords
FROM 
    MovieInfo
ORDER BY 
    production_year DESC, movie_title ASC;
