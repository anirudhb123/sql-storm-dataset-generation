WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(mc.company_name, 'Independent') AS company_name,
    COALESCE(mc.company_type, 'Not Specified') AS company_type,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ac.actor_count > 10 THEN 'Popular' 
        WHEN ac.actor_count = 0 THEN 'Uncasted' 
        ELSE 'Moderate' 
    END AS audience_type,
    CASE 
        WHEN rm.title_rank IS NULL THEN 'No Rank Available'
        ELSE 'Rank ' || rm.title_rank
    END AS title_rank_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, rm.title;
