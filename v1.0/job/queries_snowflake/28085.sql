WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.name AS company_name,
        a.name AS actor_name,
        p.gender,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, c.name, a.name, p.gender
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        company_name,
        actor_name,
        gender,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_within_year
    FROM 
        MovieDetails
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.kind_id,
    rm.company_name,
    rm.actor_name,
    rm.gender,
    rm.keyword_count
FROM 
    RankedMovies rm
WHERE 
    rm.rank_within_year <= 5
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;
