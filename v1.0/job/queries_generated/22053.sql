WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
    GROUP BY 
        a.person_id, a.name
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cp.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cp ON mc.company_id = cp.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MixedInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT i.info, ', ') AS info_details
    FROM 
        movie_info m
    JOIN 
        movie_info_idx idx ON m.id = idx.id
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.name AS actor_name,
    a.movie_count,
    a.keywords,
    cm.company_name,
    cm.company_type,
    COALESCE(mi.info_details, 'No Additional Info') AS additional_info
FROM 
    RankedMovies r
JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
JOIN 
    ActorInfo a ON ci.person_id = a.person_id 
LEFT JOIN 
    CompanyMovies cm ON r.movie_id = cm.movie_id
LEFT JOIN 
    MixedInfo mi ON r.movie_id = mi.movie_id
WHERE 
    a.movie_count > 3
    AND r.production_year = (SELECT MAX(production_year) FROM RankedMovies)
ORDER BY 
    r.production_year DESC, a.movie_count DESC, r.title;
