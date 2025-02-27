WITH RECURSIVE MovieSeries AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        CASE 
            WHEN t.episode_of_id IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS is_episode
    FROM title t
    WHERE t.title IS NOT NULL
    
    UNION ALL
    
    SELECT 
        t2.id,
        t2.title,
        t2.production_year,
        t2.season_nr,
        t2.episode_nr,
        CASE 
            WHEN t2.episode_of_id IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END
    FROM title t2
    JOIN MovieSeries ms ON t2.episode_of_id = ms.title_id
), 

Roles AS (
    SELECT 
        ci.person_id,
        ct.kind AS role_type,
        COUNT(*) AS movies_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.person_id, ct.kind
),

DetailedRoles AS (
    SELECT 
        r.person_id,
        r.role_type,
        r.movies_count,
        ak.name AS actor_name,
        ak.md5sum AS actor_md5sum
    FROM Roles r
    JOIN aka_name ak ON r.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

MovieDetails AS (
    SELECT 
        ms.title_id,
        ms.title,
        ms.production_year,
        mv.keywords,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.title) AS ranking
    FROM MovieSeries ms
    LEFT JOIN MovieKeywords mv ON ms.title_id = mv.movie_id
)

SELECT
    md.title_id,
    md.title,
    md.production_year,
    md.keywords,
    dr.actor_name,
    dr.role_type,
    dr.movies_count,
    COALESCE(dr.actor_md5sum, 'N/A') AS actor_md5sum,
    CASE 
        WHEN md.production_year < 2000 THEN 'Pre-2000s' 
        ELSE 'Post-2000s' 
    END AS era_category,
    CASE
        WHEN dr.movies_count > 0 THEN TRUE
        ELSE FALSE
    END AS has_roles
FROM MovieDetails md
LEFT JOIN DetailedRoles dr ON md.title_id IN (
    SELECT ci.movie_id
    FROM cast_info ci
    WHERE ci.person_id IN (
        SELECT DISTINCT person_id FROM aka_name
    )
)
WHERE 
    md.ranking <= 10
    AND (md.keywords IS NOT NULL OR EXISTS (
        SELECT 1 FROM movie_info mi WHERE mi.movie_id = md.title_id AND mi.note IS NOT NULL
    ))
ORDER BY md.production_year DESC, md.title ASC;
