WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.person_id) AS actors,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        actors,
        company_count,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC, company_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    r.title,
    r.production_year,
    r.actors,
    r.company_count,
    r.keyword_count,
    r.rank,
    (SELECT COUNT(*) FROM RankedMovies rm WHERE rm.production_year = r.production_year) AS total_movies_in_year,
    (SELECT STRING_AGG(name, ', ') FROM name n WHERE n.id IN (SELECT UNNEST(r.actors))) AS actors_names
FROM 
    RankedMovies r
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year, r.rank;
