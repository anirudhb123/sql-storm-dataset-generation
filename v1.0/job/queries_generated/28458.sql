WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_kind,
        a.name AS actor_name,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        aka_title t
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    INNER JOIN 
        cast_info ca ON t.id = ca.movie_id
    INNER JOIN 
        aka_name a ON ca.person_id = a.person_id
    INNER JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, cn.name, ct.kind, a.name
),
RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY movie_keyword ORDER BY actor_count DESC) AS rank_by_keyword
    FROM 
        MovieDetails md
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    company_kind,
    actor_name,
    actor_count,
    rank_by_keyword
FROM 
    RankedMovies
WHERE 
    rank_by_keyword <= 5
ORDER BY 
    movie_keyword, actor_count DESC, production_year DESC;
