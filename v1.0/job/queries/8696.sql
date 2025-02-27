
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY tk.keyword) AS keyword_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
),
DirectorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS director_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        r.title,
        rt.director_count,
        ci.companies,
        ARRAY_AGG(DISTINCT r.keyword) AS keywords
    FROM 
        RankedTitles r
    JOIN 
        DirectorRoles rt ON r.title_id = rt.movie_id
    JOIN 
        CompanyInfo ci ON rt.movie_id = ci.movie_id
    GROUP BY 
        r.title, rt.director_count, ci.companies
)
SELECT 
    title,
    director_count,
    companies,
    keywords
FROM 
    DetailedMovieInfo
WHERE 
    director_count > 1
ORDER BY 
    director_count DESC, title;
