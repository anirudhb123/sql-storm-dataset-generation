WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS associated_keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        COUNT(ca.person_id) AS total_cast_members
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind, a.name
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast_members DESC) AS rank
    FROM 
        MovieDetails
)

SELECT 
    movie_title,
    production_year,
    associated_keyword,
    company_type,
    actor_name,
    total_cast_members
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, total_cast_members DESC;
