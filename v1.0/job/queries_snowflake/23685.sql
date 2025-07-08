
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        rn_r.rank AS role_rank,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    JOIN (
        SELECT 
            ci.movie_id,
            ci.person_id,
            ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
        FROM cast_info ci
    ) rn_r ON ci.movie_id = rn_r.movie_id AND ci.person_id = rn_r.person_id
    WHERE 
        t.production_year > 2000
        AND ak.name IS NOT NULL
        AND (t.kind_id IS NOT NULL OR t.kind_id <> 0)
    GROUP BY 
        t.id, ak.name, t.title, t.production_year, rn_r.rank
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(kc.keyword, ', ') AS combined_keywords
    FROM movie_keyword mk
    JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY mk.movie_id
),
HighRoleRank AS (
    SELECT 
        movie_id,
        MAX(role_rank) AS max_rank
    FROM RankedMovies
    GROUP BY movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.keyword_count,
    tk.combined_keywords,
    CASE 
        WHEN hrr.max_rank IS NULL THEN 'No Roles'
        WHEN hrr.max_rank < 3 THEN 'Minor Role'
        ELSE 'Major Role'
    END AS role_category
FROM 
    RankedMovies rm
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    HighRoleRank hrr ON rm.movie_id = hrr.movie_id
WHERE 
    rm.keyword_count > 2 
    OR tk.combined_keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC,
    rm.keyword_count DESC NULLS LAST
LIMIT 50 OFFSET 10;
