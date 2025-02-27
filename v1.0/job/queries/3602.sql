
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        t.id
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        RankedTitles rt ON ci.movie_id = rt.id
    WHERE 
        rt.rn <= 5
    GROUP BY 
        ci.movie_id, actor_name
),
MovieDetails AS (
    SELECT 
        mt.title,
        fc.actor_name,
        fc.role_count,
        COUNT(mk.keyword_id) AS keyword_count,
        mt.production_year
    FROM 
        RankedTitles mt
    LEFT JOIN 
        FilteredCast fc ON mt.id = fc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title, fc.actor_name, fc.role_count, mt.production_year
)
SELECT 
    md.title,
    md.actor_name,
    md.role_count,
    md.keyword_count,
    CASE 
        WHEN md.role_count IS NULL THEN 'No Roles'
        ELSE 'Has Roles'
    END AS role_status,
    CONCAT(md.actor_name, ' acted in ', md.title, ' released in ', md.production_year) AS description
FROM 
    MovieDetails md
WHERE 
    md.role_count > 1
ORDER BY 
    md.keyword_count DESC, md.role_count DESC
LIMIT 10;
