
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ax.name AS actor_name,
    rm.title,
    rm.production_year,
    ac.actor_count,
    mk.keywords
FROM 
    aka_name ax
JOIN 
    cast_info ci ON ax.person_id = ci.person_id
JOIN 
    RankedMovies rm ON ci.movie_id = rm.title_id
LEFT JOIN 
    ActorCount ac ON ci.movie_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON ci.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
AND 
    (ac.actor_count IS NULL OR ac.actor_count > 2)
ORDER BY 
    rm.production_year DESC, actor_name;
