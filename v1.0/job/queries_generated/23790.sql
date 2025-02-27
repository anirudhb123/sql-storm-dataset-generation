WITH recursive actor_rank AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM 
        cast_info ca
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    LEFT JOIN 
        aka_title at ON ca.movie_id = at.movie_id
    LEFT JOIN 
        title t ON t.id = ca.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = ca.movie_id
    WHERE 
        at.kind_id IS NOT NULL AND 
        t.production_year IS NOT NULL AND 
        (mi.info IS NULL OR mi.info_type_id != 5)
    GROUP BY 
        ca.person_id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        ar.movie_count,
        ar.rank
    FROM 
        actor_rank ar
    JOIN 
        aka_name ak ON ak.person_id = ar.person_id
    WHERE 
        ar.rank <= 10
),
movie_statistics AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(COALESCE(t.season_nr, 0)) AS total_seasons,
        SUM(COALESCE(t.episode_nr, 0)) AS total_episodes
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_title at ON m.id = at.movie_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
final_report AS (
    SELECT 
        ad.actor_name,
        ms.movie_title,
        ms.total_cast,
        ms.total_seasons,
        ms.total_episodes,
        ms.total_cast + (CASE WHEN ms.total_episodes = 0 THEN 1 ELSE ms.total_episodes END) AS adjusted_cast_count
    FROM 
        actor_details ad
    JOIN 
        movie_statistics ms ON ms.total_cast >= ad.movie_count
)
SELECT 
    fr.actor_name,
    fr.movie_title,
    fr.total_cast,
    fr.total_seasons,
    fr.total_episodes,
    fr.adjusted_cast_count,
    CASE 
        WHEN fr.adjusted_cast_count IS NULL OR fr.total_cast IS NULL THEN 'Missing data'
        ELSE 'Data present'
    END AS data_status,
    CONCAT(fr.actor_name, ' appeared in ', fr.movie_title) AS info_string
FROM 
    final_report fr
WHERE 
    fr.total_cast >= 5 AND 
    fr.total_episodes < 50
ORDER BY 
    fr.adjusted_cast_count DESC,
    fr.actor_name ASC;
