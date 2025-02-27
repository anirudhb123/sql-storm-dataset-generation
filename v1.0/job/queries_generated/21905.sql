WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
BonusActors AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_actors,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS actor_with_notes_ratio
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(B.total_actors, 0) AS actor_count,
        COALESCE(B.actor_with_notes_ratio, 0) AS notes_ratio,
        K.keywords,
        R.movie_id AS ranked_movie_id,
        R.title AS ranked_title,
        R.rn
    FROM 
        BonusActors B
    FULL OUTER JOIN RankedMovies R ON B.movie_id = R.movie_id
    LEFT JOIN TopKeywords K ON R.movie_id = K.movie_id
)
SELECT 
    D.movie_id,
    D.ranked_title,
    D.production_year,
    CASE 
        WHEN D.actor_count > 0 THEN D.actor_count 
        ELSE NULL 
    END AS total_actors,
    D.notes_ratio,
    CASE 
        WHEN D.actor_count > 0 THEN (D.notes_ratio * 1.0 / D.actor_count)
        ELSE NULL 
    END AS notes_ratio_per_actor,
    CASE 
        WHEN D.actor_count IS NULL AND D.rn IS NULL THEN 'No Data' 
        ELSE 'Available' 
    END AS availability,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = D.movie_id AND mi.info_type_id = 1) AS info_count
FROM 
    DetailedInfo D 
WHERE 
    (D.notes_ratio IS NOT NULL OR D.total_actors > 10)
ORDER BY 
    D.production_year DESC,
    D.rn ASC
LIMIT 100 OFFSET 50

