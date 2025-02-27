WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        ci.note AS role_note
    FROM 
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order IS NOT NULL
),
CombinedDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ad.actor_name,
        ad.role_note,
        STRING_AGG(rm.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.movie_id = ad.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ad.actor_name, ad.role_note
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.role_note,
    cd.keywords
FROM 
    CombinedDetails cd
WHERE 
    cd.actor_name IS NOT NULL
ORDER BY 
    cd.production_year DESC,
    cd.movie_id;