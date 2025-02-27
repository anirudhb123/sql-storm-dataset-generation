
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorKeywords AS (
    SELECT 
        ci.movie_id,
        ak.keyword
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword ak ON mk.keyword_id = ak.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ExtendedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ad.actors_count, 0) AS actors_count,
        COALESCE(cd.company_count, 0) AS company_count,
        COALESCE(ak.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT person_id) AS actors_count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) ad ON rm.movie_id = ad.movie_id
    LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(keyword, ', ') AS keywords
        FROM 
            ActorKeywords
        GROUP BY 
            movie_id
    ) ak ON rm.movie_id = ak.movie_id
)
SELECT 
    em.title,
    em.production_year,
    em.actors_count,
    em.company_count,
    em.keywords,
    CASE 
        WHEN em.keywords IS NULL OR em.keywords = 'No keywords' THEN 'No related keywords found'
        ELSE 'Keywords present'
    END AS keyword_status,
    CASE 
        WHEN em.actors_count > 10 THEN 'More than 10 actors'
        WHEN em.actors_count BETWEEN 5 AND 10 THEN '5-10 actors'
        ELSE 'Fewer than 5 actors'
    END AS actor_range
FROM 
    ExtendedMovieInfo em
WHERE 
    em.production_year BETWEEN 2000 AND 2023
ORDER BY 
    em.production_year DESC, em.actors_count DESC, em.title
LIMIT 50 OFFSET 0;
