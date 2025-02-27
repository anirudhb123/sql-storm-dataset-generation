WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        p.id AS person_id,
        a.name AS actor_name,
        (SELECT COUNT(*) FROM cast_info ci2 WHERE ci2.movie_id = ci.movie_id) AS total_roles_per_movie
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        a.name IS NOT NULL AND 
        ci.nr_order IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovies AS (
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(fc.actor_name, 'No Cast') AS lead_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    cc.company_name,
    cc.company_type,
    rm.year_rank,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Old Movie'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Recent Movie'
        ELSE 'Modern Movie'
    END AS movie_category,
    COUNT(DISTINCT fc.person_id) OVER (PARTITION BY rm.movie_id) AS distinct_actors_count
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovies cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.year_rank <= 5 OR (cc.company_type IS NOT NULL AND cc.company_type LIKE '%Production%')
ORDER BY 
    rm.production_year DESC, 
    rm.title;
