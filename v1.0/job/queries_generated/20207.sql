WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        r.role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.id, c.name, ct.kind
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
SubQueryNullLogic AS (
    SELECT 
        m.movie_id,
        m.keyword_count,
        COALESCE(mk.keyword_count, 0) AS associated_keywords
    FROM 
        MovieKeywordCounts mk
    RIGHT JOIN 
        RankedMovies m ON mk.movie_id = m.movie_id
),
FinalResults AS (
    SELECT 
        a.movie_id,
        a.name AS actor_name,
        a.movie_id,
        m.production_year,
        c.company_name,
        c.company_type,
        s.associated_keywords
    FROM 
        ActorMovieInfo a
    JOIN 
        SubQueryNullLogic s ON a.movie_id = s.movie_id
    LEFT JOIN 
        MovieCompDetails c ON a.movie_id = c.movie_id
    WHERE 
        s.associated_keywords > 0
    ORDER BY 
        m.production_year DESC, a.actor_name
)
SELECT 
    fr.actor_name,
    COUNT(DISTINCT fr.movie_id) AS total_movies,
    STRING_AGG(DISTINCT fr.company_name || ' (' || fr.company_type || ')', ', ') AS companies_involved
FROM 
    FinalResults fr
GROUP BY 
    fr.actor_name
HAVING 
    COUNT(DISTINCT fr.movie_id) > (
        SELECT 
            AVG(total_movies) 
        FROM (
            SELECT 
                actor_name,
                COUNT(DISTINCT movie_id) AS total_movies
            FROM 
                FinalResults
            GROUP BY 
                actor_name
        ) AS avg_movies
    )
ORDER BY
    total_movies DESC;
