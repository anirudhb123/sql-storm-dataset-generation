WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
),
CompanyMovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mi.info, 'No info available') AS movie_info
    FROM 
        TopRankedMovies m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = 1 -- Assuming 1 is some info Type
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        ak.name,
        ak.surname_pcode,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(c.movie_id) DESC) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
    GROUP BY 
        p.id, ak.name, ak.surname_pcode
)
SELECT 
    cm.title,
    cm.production_year,
    cm.company_name,
    cm.company_type,
    COUNT(DISTINCT a.person_id) FILTER (WHERE a.movie_count > 1) AS prolific_actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS prolific_actor_names
FROM 
    CompanyMovieDetails cm
LEFT JOIN 
    ActorDetails a ON cm.movie_id = (
        SELECT 
            DISTINCT c.movie_id
        FROM 
            cast_info c 
        WHERE 
            c.person_id = a.person_id
        LIMIT 1
    )
GROUP BY 
    cm.movie_id, cm.title, cm.production_year, cm.company_name, cm.company_type
ORDER BY 
    cm.production_year DESC,
    prolific_actor_count DESC,
    cm.title
LIMIT 10
OFFSET 5;
