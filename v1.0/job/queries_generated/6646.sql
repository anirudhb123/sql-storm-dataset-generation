WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        a.name AS actor_name,
        c.nr_order,
        r.role AS actor_role
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
KeywordDetails AS (
    SELECT 
        md.movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_keyword mk ON md.movie_title = mk.movie_id
    GROUP BY 
        md.movie_title
),
CompanyDetails AS (
    SELECT 
        md.movie_title,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MovieDetails md
    JOIN 
        movie_companies mc ON md.movie_title = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        md.movie_title
)
SELECT 
    md.movie_title,
    md.production_year,
    k.keyword_count,
    c.companies,
    c.company_count
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails k ON md.movie_title = k.movie_title
LEFT JOIN 
    CompanyDetails c ON md.movie_title = c.movie_title
ORDER BY 
    md.production_year DESC, md.movie_title;
