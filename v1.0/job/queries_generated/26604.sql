WITH MovieTitles AS (
    SELECT
        mt.title,
        mt.production_year,
        mt.kind_id,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.person_id) AS cast_members,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title mt ON ak.movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
Companies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        mv.title,
        mv.production_year,
        mv.kind_id,
        mv.movie_keyword,
        mv.cast_members,
        mv.aka_names,
        comp.company_names,
        comp.company_types
    FROM 
        MovieTitles mv
    LEFT JOIN 
        Companies comp ON mv.id = comp.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.kind_id,
    md.movie_keyword,
    md.cast_members,
    md.aka_names,
    md.company_names,
    md.company_types
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.title;

This SQL query uses Common Table Expressions (CTEs) to first gather movie titles and their details along with associated keywords and cast members, and then collect company names and types linked to those movies. Finally, it retrieves all this information for movies produced between 2000 and 2023, ordering the results by production year in descending order and by title. This query effectively benchmarks string processing by working with various text fields across multiple tables.
