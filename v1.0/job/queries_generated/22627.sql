WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        CASE 
            WHEN a.name IS NULL THEN 'Unknown Actor'
            ELSE a.name
        END AS actor_name,
        COUNT(DISTINCT c.movie_id) AS film_count,
        MAX(c.nr_order) AS highest_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),

CompanyRoles AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cc.kind) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

KeywordDetails AS (
    SELECT 
        k.id,
        k.keyword,
        COUNT(mk.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mk.movie_id::text, ', ') AS movie_ids
    FROM 
        keyword k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.id, k.keyword
)

SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.film_count,
    cr.company_count,
    cr.company_names,
    kd.keyword,
    kd.movie_count,
    kd.movie_ids
FROM 
    RankedMovies rm
JOIN 
    ActorDetails ad ON EXISTS (
        SELECT 1
        FROM cast_info c
        WHERE c.movie_id = rm.title_id AND c.person_id = ad.person_id
    )
LEFT JOIN 
    CompanyRoles cr ON cr.movie_id = rm.title_id
LEFT JOIN 
    KeywordDetails kd ON kd.movie_count > 5 AND 
                         kd.id IN (
                             SELECT mk.keyword_id 
                             FROM movie_keyword mk 
                             WHERE mk.movie_id = rm.title_id
                         )
WHERE 
    (rm.rank_per_year BETWEEN 1 AND 5 OR rm.production_year < 2000)
ORDER BY 
    rm.production_year DESC, 
    ad.film_count DESC
LIMIT 100;
