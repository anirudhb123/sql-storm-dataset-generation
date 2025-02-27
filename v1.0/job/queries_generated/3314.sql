WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        COUNT(c.id) AS role_count,
        AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_info
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    GROUP BY 
        ak.name, c.movie_id
),
MovieSummaries AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(mk.keyword::text), 'No keywords') AS keywords,
        COUNT(DISTINCT cc.subject_id) AS cast_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    GROUP BY 
        m.id, m.title
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        ad.actor_name,
        ad.role_count,
        ms.cast_count,
        ms.keywords,
        RANK() OVER (ORDER BY ms.cast_count DESC) AS cast_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorDetails ad ON rm.title = ad.title
    JOIN 
        MovieSummaries ms ON rm.id = ms.movie_id
    WHERE 
        ad.role_count > 0
)
SELECT 
    title,
    production_year,
    actor_name,
    role_count,
    cast_count,
    keywords,
    cast_rank
FROM 
    FinalResults
WHERE 
    (production_year BETWEEN 2000 AND 2023) 
    AND (LOWER(keywords) LIKE '%action%' OR keywords = 'No keywords')
ORDER BY 
    production_year DESC, cast_rank ASC;
