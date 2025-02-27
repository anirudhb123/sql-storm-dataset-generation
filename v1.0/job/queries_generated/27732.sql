WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
movie_info_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_summary
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    mc.total_cast,
    mc.actor_names,
    mis.info_summary,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_info_summary mis ON rm.movie_id = mis.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.rank, mc.total_cast, mc.actor_names, mis.info_summary
ORDER BY 
    rm.production_year DESC, rm.rank;
