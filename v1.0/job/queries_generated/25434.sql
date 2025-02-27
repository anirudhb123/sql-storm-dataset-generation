WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT cni.note) AS company_notes
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type iti ON mi.info_type_id = iti.id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.production_year >= 2000 
        AND iti.info ILIKE '%award%'
    GROUP BY 
        t.id, t.title, t.production_year
),
AggregatedData AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.keywords,
        md.cast_count,
        COALESCE(SUM(CASE WHEN cnt.kind = 'Production' THEN 1 ELSE 0 END), 0) AS production_companies,
        COALESCE(SUM(CASE WHEN cnt.kind = 'Distribution' THEN 1 ELSE 0 END), 0) AS distribution_companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cnt ON mc.company_type_id = cnt.id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.aka_names, md.keywords, md.cast_count
)
SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    keywords,
    cast_count,
    production_companies,
    distribution_companies
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, cast_count DESC;
