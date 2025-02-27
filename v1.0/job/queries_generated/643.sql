WITH MovieTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS year_rank
    FROM 
        aka_title a 
    WHERE 
        a.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        title_id, 
        title, 
        production_year 
    FROM 
        MovieTitles 
    WHERE 
        year_rank <= 5
),
CastRoles AS (
    SELECT 
        c.movie_id,
        COALESCE(r.role, 'Unknown') AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        t.title_id,
        t.title,
        t.production_year,
        COALESCE(cr.role_name, 'No role') AS role_name,
        COALESCE(cr.role_count, 0) AS role_count
    FROM 
        TopTitles t
    LEFT JOIN 
        CastRoles cr ON t.title_id = cr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.role_name,
    md.role_count,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    COUNT(DISTINCT mk.keyword_id) AS num_keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.title_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON md.title_id = mk.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.role_count > 0
GROUP BY 
    md.title, md.production_year, md.role_name, md.role_count
ORDER BY 
    md.production_year DESC, md.role_count DESC;
