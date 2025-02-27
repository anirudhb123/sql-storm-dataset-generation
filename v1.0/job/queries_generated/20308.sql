WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCareer AS (
    SELECT 
        a.person_id,
        a.movie_id,
        COUNT(DISTINCT a.role_id) AS total_roles,
        STRING_AGG(DISTINCT a.note, ', ') AS role_notes
    FROM 
        cast_info a
    JOIN 
        RankedMovies rm ON a.movie_id = rm.movie_id
    WHERE 
        a.nr_order IS NOT NULL
    GROUP BY 
        a.person_id, a.movie_id
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        ac.total_roles,
        ac.role_notes
    FROM 
        aka_name p
    LEFT JOIN 
        ActorCareer ac ON p.person_id = ac.person_id
    WHERE 
        p.name IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        DISTINCT t.id AS title_id,
        t.title,
        COALESCE(t.production_year, 1900) AS effective_year
    FROM 
        aka_title t
    LEFT JOIN 
        actor_details ad ON ad.total_roles IS NOT NULL
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    ORDER BY 
        effective_year DESC
)
SELECT 
    ft.title,
    CONCAT('Year: ', ft.effective_year) AS movie_year,
    CAST(COALESCE(ad.actor_name, 'Unknown Actor') AS VARCHAR(255)) AS actor_name,
    ad.total_roles,
    ad.role_notes
FROM 
    FilteredTitles ft
LEFT JOIN 
    ActorDetails ad ON ft.title_id IN (
        SELECT movie_id 
        FROM cast_info ci 
        WHERE ci.person_id = ad.person_id
    )
ORDER BY 
    ft.effective_year DESC,
    ad.total_roles DESC NULLS LAST
LIMIT 50;

