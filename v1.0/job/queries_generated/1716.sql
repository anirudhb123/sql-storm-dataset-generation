WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year,
        COUNT(DISTINCT m.id) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%drama%'
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cm.company_name, 'Independent') AS producing_company,
        COALESCE(cm.company_type, 'N/A') AS type_of_company,
        rt.total_movies
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyMovies cm ON rt.title = cm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.producing_company,
    md.type_of_company,
    CASE 
        WHEN md.total_movies > 0 THEN ROUND((md.total_movies / NULLIF(COUNT(md.title) OVER(), 0)::float) * 100, 2)
        ELSE 0
    END AS percentage_of_years_total_movies
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.title ASC;
