WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title m
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieRankings AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year,
        actor_names, 
        keyword_count, 
        company_count,
        RANK() OVER (ORDER BY keyword_count DESC, company_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    mr.rank AS movie_rank,
    mr.movie_title,
    mr.production_year,
    mr.actor_names,
    mr.keyword_count,
    mr.company_count
FROM 
    MovieRankings mr
WHERE 
    mr.rank <= 10
ORDER BY 
    mr.rank;
