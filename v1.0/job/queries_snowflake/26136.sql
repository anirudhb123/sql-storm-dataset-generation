WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        rt.role AS role,
        a.name AS actor_name,
        m.info AS movie_info
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    WHERE 
        t.production_year > 2000
),
KeywordCounts AS (
    SELECT
        movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.role,
        md.actor_name,
        md.movie_info,
        kc.keyword_count,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, kc.keyword_count DESC) AS movie_rank
    FROM 
        MovieDetails md
    JOIN 
        KeywordCounts kc ON md.movie_id = kc.movie_id
)

SELECT 
    movie_rank,
    title,
    production_year,
    company_name,
    role,
    actor_name,
    movie_info
FROM 
    RankedMovies
WHERE 
    movie_rank <= 10;

