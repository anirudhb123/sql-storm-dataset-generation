WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank,
        COALESCE(CAST(mi.info AS TEXT), 'N/A') AS movie_info,
        CASE 
            WHEN c.nr_order IS NULL THEN 'Unknown Order'
            ELSE CAST(c.nr_order AS TEXT)
        END AS order_info
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    WHERE 
        a.name IS NOT NULL AND
        t.production_year IS NOT NULL
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count,
        MAX(production_year) AS latest_year,
        STRING_AGG(DISTINCT movie_info, '; ') AS movie_infos
    FROM 
        ranked_titles
    WHERE 
        title_rank <= 5
    GROUP BY 
        actor_name
),
movies_with_keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    asum.actor_name,
    asum.movie_count,
    asum.latest_year,
    CASE 
        WHEN asum.latest_year < (SELECT MAX(production_year) FROM aka_title) - 10 THEN 'Veteran'
        ELSE 'Active'
    END AS actor_status,
    COALESCE(mwk.keywords, ARRAY['No Keywords']) AS keywords,
    asum.movie_infos
FROM 
    actor_summary asum
LEFT JOIN 
    movies_with_keywords mwk ON asum.actor_name = mwk.title
WHERE 
    asum.movie_count > 3
ORDER BY 
    asum.latest_year DESC, asum.actor_name ASC;
