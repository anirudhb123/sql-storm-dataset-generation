
WITH RankedTitles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        p.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
),
AggregatedMovieInfo AS (
    SELECT 
        m.movie_id,
        COUNT(mi.id) AS info_count,
        LISTAGG(mi.info, '; ') AS combined_info
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        m.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    r.kind_id,
    r.keyword,
    f.actor_name,
    f.actor_role,
    a.info_count,
    a.combined_info
FROM 
    RankedTitles r
LEFT JOIN 
    FilteredCast f ON r.title_id = f.movie_id AND f.role_rank = 1
LEFT JOIN 
    AggregatedMovieInfo a ON r.title_id = a.movie_id
WHERE 
    r.rank = 1
ORDER BY 
    r.production_year DESC, r.title;
