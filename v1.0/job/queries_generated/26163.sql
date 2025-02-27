WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c1.name AS company_name,
        c2.kind AS company_type,
        a.name AS actor_name,
        rp.role AS role,
        COUNT(mk.id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c1 ON mc.company_id = c1.id
    JOIN 
        company_type c2 ON mc.company_type_id = c2.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rp ON ci.role_id = rp.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, k.keyword, c1.name, c2.kind, a.name, rp.role
),
KeywordStatistics AS (
    SELECT 
        movie_keyword,
        AVG(keyword_count) AS avg_keywords_per_movie,
        COUNT(*) AS total_movies
    FROM 
        MovieDetails
    GROUP BY 
        movie_keyword
)

SELECT 
    ds.movie_title,
    ds.production_year,
    ds.actor_name,
    ds.company_name,
    ds.role,
    ks.avg_keywords_per_movie,
    ks.total_movies
FROM 
    MovieDetails ds
JOIN 
    KeywordStatistics ks ON ds.movie_keyword = ks.movie_keyword
ORDER BY 
    ds.production_year DESC, 
    ds.keyword_count DESC, 
    ds.movie_title;
