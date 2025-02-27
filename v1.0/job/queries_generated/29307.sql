WITH movie_statistics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

serials AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(CAST(season_nr AS VARCHAR) || '-' || CAST(episode_nr AS VARCHAR), ', ' ORDER BY season_nr, episode_nr) AS episode_list
    FROM 
        title 
    WHERE 
        episode_of_id IS NOT NULL
    GROUP BY 
        title, production_year
)

SELECT 
    ms.movie_title,
    ms.production_year,
    ms.cast_names,
    ms.keyword_count,
    ms.production_companies,
    s.episode_list
FROM 
    movie_statistics ms
LEFT JOIN 
    serials s ON ms.movie_title = s.title AND ms.production_year = s.production_year
ORDER BY 
    ms.production_year DESC, ms.keyword_count DESC;
