WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    ),
    MovieActors AS (
        SELECT 
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS actor_count,
            STRING_AGG(DISTINCT an.name, ', ') AS actor_names
        FROM 
            cast_info ci
        JOIN 
            aka_name an ON ci.person_id = an.person_id
        GROUP BY 
            ci.movie_id
        HAVING 
            COUNT(DISTINCT ci.person_id) >= 5 -- considering only movies with at least 5 actors
    ),
    MovieKeywords AS (
        SELECT 
            mk.movie_id,
            COUNT(DISTINCT k.keyword) AS keyword_count,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ),
    MovieCompanies AS (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT c.id) AS company_count,
            STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
    ma.actor_count,
    ma.actor_names,
    mk.keyword_count,
    mk.keywords,
    mc.company_count,
    mc.company_names,
    COALESCE(mr.note, 'No note available') AS movie_note
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieActors ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mr ON rm.movie_id = mr.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
WHERE 
    rm.year_rank <= 10  -- getting top 10 recent movies by kind
    AND (ma.actor_count IS NULL OR ma.actor_count >= 10)  -- either no actors or more than 10 actors
ORDER BY 
    rm.production_year DESC,
    ma.actor_count DESC
LIMIT 50;  -- limiting to 50 results for performance benchmarking
