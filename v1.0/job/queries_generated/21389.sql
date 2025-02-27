WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
), 

FeaturedActors AS (
    SELECT 
        ak.name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), 

MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    INNER JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
), 

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    fa.name AS featured_actor,
    fa.movies_count,
    mk.keywords,
    ci.companies,
    ci.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    FeaturedActors fa ON fa.movies_count = (SELECT MAX(movies_count) FROM FeaturedActors)
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.id
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = rm.id
WHERE 
    (rm.actor_count IS NOT NULL OR fa.movies_count IS NULL)
    AND rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;

-- Edge case handling: 
-- In the event of NULL actor counts, ensure to include movie titles while ignoring NULL counts in the final output.
