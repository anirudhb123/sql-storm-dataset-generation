WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
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
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.total_companies,
        cs.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.total_companies, 0) AS total_companies,
    md.company_names,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = md.movie_id AND mi.info_type_id IN (
         SELECT it.id FROM info_type it WHERE it.info = 'description' OR it.info LIKE '%award%'
     )) AS award_info_count,
    (SELECT STRING_AGG(kw.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = md.movie_id) AS keywords 
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;
