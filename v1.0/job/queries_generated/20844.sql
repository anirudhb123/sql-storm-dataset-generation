WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT m.id) AS movies_count,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles
    FROM 
        cast_info c
    JOIN 
        aka_name an ON c.person_id = an.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    JOIN 
        title t ON at.movie_id = t.id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        c.person_id
), 
SectorMovies AS (
    SELECT 
        mc.movie_id,
        cm.kind AS company_kind,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type cm ON mc.company_type_id = cm.id
    WHERE 
        cm.kind LIKE 'Production%'
    GROUP BY 
        mc.movie_id, cm.kind
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 2
)
SELECT 
    ah.person_id,
    ah.movies_count,
    ah.movie_titles,
    COALESCE(sm.company_count, 0) AS total_company_in_movies,
    pk.keyword,
    pk.keyword_count
FROM 
    ActorHierarchy ah
LEFT JOIN 
    SectorMovies sm ON sm.movie_id IN (
        SELECT
            DISTINCT c.movie_id
        FROM 
            cast_info c
        WHERE 
            c.person_id = ah.person_id
    )
LEFT JOIN 
    PopularKeywords pk ON pk.movie_id IN (
        SELECT 
            DISTINCT c.movie_id
        FROM 
            cast_info c
        JOIN 
            aka_name an ON c.person_id = an.person_id
        WHERE 
            c.person_id = ah.person_id
    )
WHERE 
    ah.movies_count > 5
ORDER BY 
    ah.movies_count DESC,
    total_company_in_movies DESC,
    pk.keyword_count DESC NULLS LAST
LIMIT 50;
