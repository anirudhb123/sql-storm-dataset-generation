
WITH MovieActors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.movie_id ORDER BY c.nr_order) AS actor_rank,
        t.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ma.movie_title,
    ma.actor_name,
    ma.production_year,
    ci.companies,
    ci.company_count,
    ki.keywords
FROM 
    MovieActors ma
LEFT JOIN 
    CompanyInfo ci ON ma.movie_id = ci.movie_id
LEFT JOIN 
    KeywordInfo ki ON ma.movie_id = ki.movie_id
WHERE 
    ma.actor_rank <= 3
ORDER BY 
    ma.production_year DESC, 
    ma.actor_name;
