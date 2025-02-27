WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(m.production_year) ORDER BY COUNT(c.person_id) DESC) AS rank_actor_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorNames AS (
    SELECT 
        a.name AS actor_name,
        a.person_id,
        r.movie_id
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        RankedMovies r ON c.movie_id = r.movie_id
),
DistinctKeywords AS (
    SELECT 
        DISTINCT k.keyword
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.phonetic_code IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        info.info AS info_detail,
        COALESCE(mi.note, 'No additional info') AS note
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type info ON mi.info_type_id = info.id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.actor_name,
    k.keyword,
    COALESCE(mi.info_detail, 'No Info') AS info_detail,
    CASE 
        WHEN r.rank_actor_count > 5 THEN 'Popular Movie'
        ELSE 'Less Popular'
    END AS popularity_desc
FROM 
    RankedMovies r
LEFT JOIN 
    ActorNames a ON r.movie_id = a.movie_id
LEFT JOIN 
    DistinctKeywords k ON (a.actor_name ILIKE '%' || k.keyword || '%')
LEFT JOIN 
    MovieInfo mi ON r.movie_id = mi.movie_id
WHERE 
    r.rank_actor_count IS NOT NULL
    AND (k.keyword IS NOT NULL OR a.actor_name IS NOT NULL OR mi.info_detail IS NOT NULL)
ORDER BY 
    r.production_year DESC, r.rank_actor_count, a.actor_name;
