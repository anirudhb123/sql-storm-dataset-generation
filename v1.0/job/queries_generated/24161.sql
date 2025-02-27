WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
TopCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        MAX(CASE WHEN r.role = 'actor' THEN c.person_id END) AS lead_actor_id
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        tc.total_cast,
        tc.lead_actor_id,
        ko.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopCast tc ON rm.movie_id = tc.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ko ON mk.keyword_id = ko.id
),
ActorDetails AS (
    SELECT 
        p.id AS actor_id,
        p.name,
        COALESCE(pi.info, 'No Info') AS additional_info
    FROM 
        aka_name p 
    LEFT JOIN 
        person_info pi ON p.person_id = pi.person_id 
    WHERE 
        p.md5sum IS NOT NULL
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        ad.name AS lead_actor_name,
        md.keyword,
        CASE 
            WHEN md.total_cast IS NULL THEN 'No Cast Info'
            WHEN md.total_cast > 10 THEN 'Ensemble Cast'
            ELSE 'Limited Cast'
        END AS cast_category
    FROM 
        MovieDetails md
    LEFT JOIN 
        ActorDetails ad ON md.lead_actor_id = ad.actor_id
)
SELECT 
    title,
    production_year,
    total_cast,
    lead_actor_name,
    keyword,
    cast_category,
    CASE 
        WHEN keyword LIKE '%Drama%' THEN 'Drama Genre'
        WHEN keyword IS NULL THEN 'Uncategorized'
        ELSE 'Other Genre'
    END AS genre_description
FROM 
    FinalOutput
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, total_cast DESC
LIMIT 100;
