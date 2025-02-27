WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
MovieInfo AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS company_count,
        AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mc.note IS NOT NULL
    GROUP BY 
        mt.movie_id
),
PopularActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 3
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT movie_title) > 10
)
SELECT 
    pa.actor_name,
    pa.movie_count,
    mi.keywords,
    mi.company_count,
    mi.avg_info_length
FROM 
    PopularActors pa
LEFT JOIN 
    MovieInfo mi ON pa.movie_count = mi.company_count
WHERE 
    mi.avg_info_length IS NOT NULL
    AND pa.actor_name IS NOT NULL
ORDER BY 
    mi.avg_info_length DESC, pa.movie_count DESC;

