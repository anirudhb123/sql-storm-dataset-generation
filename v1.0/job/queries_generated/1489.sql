WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.info AS movie_description,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    GROUP BY 
        m.movie_id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(md.movie_description, 'No description available') AS movie_description,
    COALESCE(md.keywords, 'No keywords') AS keywords,
    COALESCE(cd.companies, 'No companies') AS companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    MovieDetails md ON rm.title_id = md.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title LIMIT 100;
