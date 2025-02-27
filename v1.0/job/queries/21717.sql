
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_per_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.person_id,
        c.movie_id,
        COALESCE(r.role, 'Unknown') AS role_name,
        COUNT(*) OVER (PARTITION BY c.person_id ORDER BY COALESCE(c.nr_order, 9999)) AS total_roles
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
CompanyTypes AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_kind
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ' ORDER BY it.id) AS movie_info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
UnusualLinks AS (
    SELECT 
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS unusual_link_count
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link LIKE '%weird%')
    GROUP BY 
        ml.movie_id
)
SELECT 
    a.name AS actor_name,
    r.movie_id,
    r.title AS movie_title,
    r.production_year,
    f.role_name,
    f.total_roles,
    c.company_kind,
    m.movie_info_details,
    COALESCE(u.unusual_link_count, 0) AS unusual_link_count
FROM 
    RankedMovies r
JOIN 
    FilteredCast f ON r.movie_id = f.movie_id
LEFT JOIN 
    CompanyTypes c ON r.movie_id = c.movie_id
LEFT JOIN 
    MovieInfo m ON r.movie_id = m.movie_id
LEFT JOIN 
    UnusualLinks u ON r.movie_id = u.movie_id
JOIN 
    aka_name a ON f.person_id = a.person_id
WHERE 
    (r.rank_per_year <= 5 OR f.total_roles > 10)
    AND r.production_year > 2000
    AND f.role_name NOT IN ('Cameo', 'Uncredited')
ORDER BY 
    r.production_year DESC, r.title, f.role_name
LIMIT 100;
