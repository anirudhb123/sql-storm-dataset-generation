WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MAX(t.production_year) AS latest_movie_year
    FROM 
        cast_info c
    JOIN 
        RankedMovies t ON c.movie_id = t.movie_id
    GROUP BY 
        c.person_id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
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
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    m.title,
    m.production_year,
    COALESCE(a.movie_count, 0) AS actor_movie_count,
    COALESCE(a.latest_movie_year, 'N/A') AS latest_actor_movie_year,
    COALESCE(ci.companies, 'No companies') AS companies,
    COALESCE(ci.company_types, 'No types') AS company_types,
    COALESCE(ki.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN a.latest_movie_year < 2000 THEN 'Classic'
        WHEN a.latest_movie_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    CASE 
        WHEN a.latest_movie_year IS NULL THEN 'No movies'
        ELSE NULL
    END AS null_check_label
FROM 
    RankedMovies m
LEFT JOIN 
    ActorStats a ON m.movie_id = a.movie_id
LEFT JOIN 
    CompanyInfo ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    KeywordInfo ki ON m.movie_id = ki.movie_id
WHERE 
    m.rank <= 3
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
