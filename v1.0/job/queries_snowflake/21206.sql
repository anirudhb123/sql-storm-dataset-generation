
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
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
),
TestJoin AS (
    SELECT 
        rm.title,
        rm.production_year,
        ad.actor_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN rm.production_year > 2000 THEN 'Modern'
            WHEN rm.production_year BETWEEN 1980 AND 2000 THEN 'Classic'
            ELSE 'Old'
        END AS era
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.title_rank <= 5
)
SELECT 
    era,
    COUNT(DISTINCT title) AS movie_count,
    COUNT(DISTINCT actor_name) AS actor_count,
    MAX(title) AS latest_movie,
    MIN(production_year) AS earliest_movie_year
FROM 
    TestJoin
WHERE 
    actor_name IS NOT NULL
GROUP BY 
    era
HAVING 
    COUNT(DISTINCT title) > 1
ORDER BY 
    CASE 
        WHEN era = 'Modern' THEN 1
        WHEN era = 'Classic' THEN 2
        ELSE 3
    END;
