WITH ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, '; ') AS movie_titles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.name
),
Companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieGenres AS (
    SELECT 
        t.id AS movie_id,
        ARRAY_AGG(DISTINCT kt.kind) AS genres
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        t.id
),
FinalReport AS (
    SELECT 
        ad.actor_id,
        ad.actor_name,
        ad.movie_count,
        ad.movie_titles,
        coalesce(c.company_names, 'No Companies') AS company_names,
        coalesce(mg.genres, ARRAY['Unknown']) AS genres
    FROM 
        ActorDetails ad
    LEFT JOIN 
        Companies c ON ad.movie_titles LIKE '%' || c.movie_id || '%'
    LEFT JOIN 
        MovieGenres mg ON ad.movie_titles LIKE '%' || mg.movie_id || '%'
)
SELECT 
    actor_id,
    actor_name,
    movie_count,
    movie_titles,
    company_names,
    genres
FROM 
    FinalReport
ORDER BY 
    movie_count DESC, 
    actor_name;
