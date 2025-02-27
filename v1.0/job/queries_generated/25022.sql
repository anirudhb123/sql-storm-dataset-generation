WITH ActorMovieInfo AS (
    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        kc.kind AS movie_kind,
        COALESCE(SUM(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS personal_info_count,
        COALESCE(SUM(CASE WHEN km.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS movie_keywords_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title kt ON ci.movie_id = kt.movie_id
    JOIN 
        kind_type kc ON kt.kind_id = kc.id
    LEFT JOIN 
        person_info pi ON ka.person_id = pi.person_id
    LEFT JOIN 
        movie_keyword km ON kt.movie_id = km.movie_id
    GROUP BY 
        ka.name, kt.title, kt.production_year, kc.kind
),
FormattedResults AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        movie_kind,
        personal_info_count,
        movie_keywords_count,
        CONCAT(actor_name, ' starred in ', movie_title, ' in ', production_year, ' - Type: ', movie_kind, 
               ' | Personal Info Count: ', personal_info_count, 
               ' | Movie Keywords Count: ', movie_keywords_count) AS summary
    FROM 
        ActorMovieInfo
)
SELECT 
    summary
FROM 
    FormattedResults
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, actor_name;
