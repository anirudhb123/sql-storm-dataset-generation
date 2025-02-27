WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ah.person_id,
        an.name,
        ah.movie_count
    FROM 
        ActorHierarchy ah
    JOIN 
        aka_name an ON ah.person_id = an.person_id
    WHERE 
        ah.rank <= 10
),
MovieInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
),
FullReport AS (
    SELECT 
        ta.name AS actor_name,
        ta.movie_count,
        mi.title,
        mi.production_year,
        mi.keyword_count,
        mi.company_names
    FROM 
        TopActors ta
    JOIN 
        cast_info ci ON ta.person_id = ci.person_id
    JOIN 
        aka_title mi ON ci.movie_id = mi.id
)
SELECT 
    fr.actor_name,
    fr.movie_count,
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.company_names,
    COALESCE(fr.company_names[1], 'No Companies') AS first_company,
    fr.keyword_count * 1.0 / NULLIF(fr.movie_count, 0) AS avg_keywords_per_movie
FROM 
    FullReport fr
ORDER BY 
    fr.movie_count DESC, fr.actor_name;
