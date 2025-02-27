WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
FinalReport AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year, 
        ad.actor_name, 
        ad.movie_count
    FROM 
        MovieDetails md
    JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    JOIN 
        aka_name ad ON ci.person_id = ad.person_id
)
SELECT 
    fr.movie_id, 
    fr.title, 
    fr.production_year, 
    fr.actor_name, 
    fr.movie_count
FROM 
    FinalReport fr
ORDER BY 
    fr.production_year DESC, 
    fr.title;
