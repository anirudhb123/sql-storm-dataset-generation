
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    INNER JOIN 
        ranked_titles rt ON c.movie_id = rt.title_id
    GROUP BY 
        c.person_id
),
top_actors AS (
    SELECT 
        ak.name,
        ac.movie_count,
        DENSE_RANK() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        aka_name ak
    INNER JOIN 
        actor_movie_counts ac ON ak.person_id = ac.person_id
    WHERE 
        ac.movie_count > 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_benchmark AS (
    SELECT 
        tt.title,
        tt.production_year,
        ta.name AS top_actor,
        mk.keywords
    FROM 
        ranked_titles tt
    LEFT JOIN 
        top_actors ta ON tt.title_id IN (
            SELECT mc.movie_id
            FROM cast_info mc
            INNER JOIN aka_name ak ON mc.person_id = ak.person_id
            WHERE ak.name = ta.name
        )
    LEFT JOIN 
        movie_keywords mk ON tt.title_id = mk.movie_id
    WHERE 
        ta.actor_rank <= 10  
)
SELECT 
    COUNT(*) AS benchmark_count,
    MIN(final_benchmark.production_year) AS earliest_year,
    MAX(final_benchmark.production_year) AS latest_year,
    STRING_AGG(DISTINCT final_benchmark.top_actor, ', ') AS top_actors_list,
    STRING_AGG(DISTINCT final_benchmark.keywords, '; ') AS combined_keywords
FROM 
    final_benchmark;
