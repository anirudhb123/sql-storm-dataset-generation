WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        name c ON ci.person_id = c.imdb_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
complete_info AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.kind,
        md.aka_names,
        md.cast_names,
        md.keyword_count,
        ci.company_names,
        ci.company_types
    FROM 
        movie_details md
    LEFT JOIN 
        company_info ci ON md.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    kind,
    aka_names,
    cast_names,
    keyword_count,
    company_names,
    company_types
FROM 
    complete_info
ORDER BY 
    production_year DESC, title;
