
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, r.role
), 
TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ar.role,
        ar.role_count,
        RANK() OVER (PARTITION BY ar.role ORDER BY ar.role_count DESC) AS role_rank
    FROM 
        aka_name a
    JOIN 
        ActorRoles ar ON a.person_id = ar.person_id
    WHERE 
        ar.role_count > (SELECT AVG(role_count) FROM ActorRoles) 
        AND ar.role IS NOT NULL
), 
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title AS Movie_Title,
    r.production_year AS Production_Year,
    ta.name AS Top_Actor,
    ta.role AS Actor_Role,
    COALESCE(mkw.keywords, 'No keywords') AS Keywords,
    r.year_rank AS Year_Rank
FROM 
    RankedMovies r
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    TopActors ta ON cc.subject_id = ta.actor_id
LEFT JOIN 
    MoviesWithKeywords mkw ON r.movie_id = mkw.movie_id
WHERE 
    r.year_rank <= 5
    AND (mkw.keywords IS NULL OR mkw.keywords LIKE '%Action%')
ORDER BY 
    r.production_year DESC, 
    r.title ASC
LIMIT 10 OFFSET 5;
