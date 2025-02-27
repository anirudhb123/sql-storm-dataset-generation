WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(i.info, 'N/A') AS info,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info i ON m.title = i.info AND m.production_year = i.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = i.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.year_rank <= 10
    GROUP BY 
        m.title, m.production_year, i.info
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        C.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name C ON mc.company_id = C.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.info,
        cd.company_name,
        cd.company_type,
        RANK() OVER (ORDER BY md.production_year DESC, md.title) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.title = cd.movie_id
)
SELECT 
    title,
    production_year,
    info,
    company_name,
    company_type
FROM 
    FinalResults
WHERE 
    rank <= 20
ORDER BY 
    production_year DESC, title;
