
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
ActorDetail AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ad.name AS actor_name,
    ad.role_rank,
    mk.keywords_list,
    COALESCE(m.note, 'No Note') AS movie_note,
    COUNT(DISTINCT mc.company_id) AS num_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetail ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info m ON rm.movie_id = m.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 10 AND 
    (ad.role_rank IS NULL OR ad.role_rank <= 3)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ad.name, ad.role_rank, mk.keywords_list, m.note
ORDER BY 
    rm.production_year DESC, rm.title;
