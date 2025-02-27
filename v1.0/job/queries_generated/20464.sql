WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        info.info AS movie_info,
        COALESCE(c.name, 'Unknown Company') AS company_name
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info info ON m.id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration')
),
CastMovieInfo AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
)
SELECT 
    md.title,
    md.production_year,
    CASE 
        WHEN md.movie_info IS NULL THEN 'Information Unavailable'
        ELSE md.movie_info
    END AS duration_info,
    STRING_AGG(DISTINCT cm.actor_name, ', ') AS actors,
    CASE 
        WHEN COUNT(DISTINCT cm.actor_name) > 5 THEN 'Star Cast'
        WHEN COUNT(DISTINCT cm.actor_name) = 0 THEN 'No Cast Available'
        ELSE 'Moderate Cast'
    END AS cast_size,
    CASE 
        WHEN MAX(rt.title_rank) = 1 THEN 'First in Year'
        ELSE 'Not First in Year'
    END AS ranking_info
FROM 
    MovieDetails md
LEFT JOIN 
    CastMovieInfo cm ON md.movie_id = cm.movie_id
LEFT JOIN 
    RankedTitles rt ON md.movie_id = rt.title_id
GROUP BY 
    md.title, md.production_year, md.movie_info
HAVING 
    SUM(CASE WHEN cm.role_name = 'Lead' THEN 1 ELSE 0 END) > 0
ORDER BY 
    md.production_year DESC, COUNT(cm.actor_name) DESC;
