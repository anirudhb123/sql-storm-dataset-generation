WITH MovieRoles AS (
    SELECT 
        ca.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    JOIN 
        role_type r ON ca.role_id = r.id
    GROUP BY 
        ca.movie_id
),
MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = t.id) AS company_count,
        mr.actor_count,
        COALESCE(kw.keyword, 'No Keywords') AS keyword
    FROM 
        title t
    LEFT JOIN 
        MovieRoles mr ON t.id = mr.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_count,
        md.actor_count,
        md.keyword,
        RANK() OVER (ORDER BY md.company_count DESC, md.actor_count DESC) AS movie_rank
    FROM 
        MovieDetails md
    WHERE 
        md.actor_count IS NOT NULL
)
SELECT 
    r.title, 
    r.production_year, 
    r.company_count, 
    r.actor_count, 
    r.keyword
FROM 
    RankedMovies r
WHERE 
    r.movie_rank <= 10
ORDER BY 
    r.movie_rank;
