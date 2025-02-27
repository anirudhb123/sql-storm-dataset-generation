WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL AND
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Subquery for kind_id
    GROUP BY
        t.id, t.title, t.production_year, k.keyword
),
ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.person_id,
        a.name,
        COALESCE(pi.info, 'No info available') AS info_status
    FROM
        aka_name a
    LEFT JOIN
        person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    ad.name AS actor_name,
    md.keyword,
    md.cast_count,
    CASE 
        WHEN ad.info_status IS NOT NULL THEN 'Biography available' 
        ELSE 'No biography available' 
    END AS biography_status,
    COUNT(*) OVER (PARTITION BY md.movie_id) AS total_actors
FROM
    MovieDetails md
LEFT JOIN
    cast_info c ON md.movie_id = c.movie_id
LEFT JOIN
    ActorDetails ad ON c.person_id = ad.person_id
WHERE
    md.role_rank = 1 -- We want only the lead role
ORDER BY
    md.production_year DESC, md.title ASC
LIMIT 50;
