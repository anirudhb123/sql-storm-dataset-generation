WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
), 
ActorSummary AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
),
MoviesWithKeyword AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%'
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    asum.actor_name,
    asum.movies_count,
    asum.has_note_ratio,
    COALESCE(mkw.keyword, 'No Keywords') AS keyword_association
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorSummary asum ON rm.rank <= 5
LEFT JOIN 
    MoviesWithKeyword mkw ON rm.title = mkw.title
WHERE 
    rm.production_year >= 2000 
    AND rm.company_count > 2
ORDER BY 
    rm.production_year DESC, rm.company_count DESC;
