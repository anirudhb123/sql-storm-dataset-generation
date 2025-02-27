WITH MovieDetails AS (
    SELECT 
        t.id AS title_id, 
        t.title AS movie_title, 
        t.production_year, 
        k.keyword AS movie_keyword, 
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND c.kind != 'Unknown'
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
), KeywordCount AS (
    SELECT 
        movie_title, 
        COUNT(DISTINCT movie_keyword) AS keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
), ActorCount AS (
    SELECT 
        movie_title, 
        COUNT(DISTINCT unnest(actor_names)) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    md.movie_title, 
    md.production_year, 
    kc.keyword_count, 
    ac.actor_count, 
    CASE 
        WHEN kc.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    MovieDetails md
JOIN 
    KeywordCount kc ON md.movie_title = kc.movie_title
JOIN 
    ActorCount ac ON md.movie_title = ac.movie_title
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC;
