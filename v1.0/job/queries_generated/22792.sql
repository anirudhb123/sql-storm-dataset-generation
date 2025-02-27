WITH movie_stats AS (
    SELECT 
        t.title,
        ct.kind AS movie_type,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(pi.info_length) AS avg_info_length,
        SUM(CASE WHEN ti.note IS NOT NULL THEN 1 ELSE 0 END) AS non_null_notes,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY ct.kind ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type ct ON t.kind_id = ct.id
    GROUP BY 
        t.title, ct.kind
),
actor_movies AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT t.title) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
ranked_movies AS (
    SELECT 
        ms.*,
        am.movie_count,
        am.notes_present
    FROM 
        movie_stats ms
    LEFT JOIN 
        actor_movies am ON ms.actor_count = am.movie_count
)
SELECT 
    *,
    CASE 
        WHEN actor_count > 0 THEN actor_count * 1.0 / NULLIF(movie_count, 0)
        ELSE 0 
    END AS actor_per_movie_ratio,
    CASE 
        WHEN notes_present > 0 THEN 'Notes Available' 
        ELSE 'No Notes' 
    END AS notes_status
FROM 
    ranked_movies
WHERE 
    actor_count > 5
    AND (movie_type LIKE 'Feature%' OR movie_type LIKE '%Documentary')
    AND (avg_info_length IS NULL OR avg_info_length > 100)
ORDER BY 
    actor_per_movie_ratio DESC, movie_type DESC;
