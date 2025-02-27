WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorNames AS (
    SELECT 
        an.person_id,
        STRING_AGG(DISTINCT an.name, ', ') AS all_names
    FROM aka_name an
    GROUP BY an.person_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        COALESCE(ac.all_names, 'No Actors') AS actors,
        COUNT(DISTINCT kc.id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN ActorNames ac ON ci.person_id = ac.person_id
    LEFT JOIN movie_keyword kc ON t.id = kc.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, ac.all_names
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keyword_count,
    md.company_count,
    RANK() OVER (ORDER BY md.keyword_count DESC) AS keyword_rank
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 5
ORDER BY 
    md.company_count DESC, 
    md.title;
