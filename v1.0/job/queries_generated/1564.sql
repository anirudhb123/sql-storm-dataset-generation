WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.name,
        cc.kind AS company_kind,
        cc.name AS company_name,
        m.title,
        m.production_year,
        COALESCE(cit.note, 'No note') AS cast_note,
        RANK() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cc ON mc.company_id = cc.id
    LEFT JOIN 
        complete_cast ccit ON m.id = ccit.movie_id AND a.id = ccit.subject_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ad.name AS actor_name,
    ad.company_kind,
    ad.company_name,
    ad.cast_note
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.title = ad.title AND rm.production_year = ad.production_year
WHERE 
    rm.rank <= 3 
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC, 
    ad.actor_rank ASC;
