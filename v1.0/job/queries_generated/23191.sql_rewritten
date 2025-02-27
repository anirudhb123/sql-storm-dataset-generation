WITH ActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS latest_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE
        a.name IS NOT NULL
    AND 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        k.keyword,
        t.production_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IS NOT NULL
    AND 
        (k.keyword IS NOT NULL OR k.keyword LIKE '%action%' OR k.keyword = '') 
),
ActorKeywordSummary AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        tk.keyword,
        COUNT(tk.title_id) AS keyword_count
    FROM 
        ActorTitles a
    LEFT JOIN 
        TitleKeywords tk ON a.movie_title = tk.keyword 
    GROUP BY 
        a.actor_id, a.actor_name, tk.keyword
)
SELECT 
    aks.actor_name,
    STRING_AGG(DISTINCT aks.keyword, ', ') AS keywords_appeared,
    MAX(at.production_year) AS latest_movie_year
FROM 
    ActorKeywordSummary aks
JOIN 
    ActorTitles at ON aks.actor_id = at.actor_id
WHERE 
    aks.keyword_count > 1 
GROUP BY 
    aks.actor_id, aks.actor_name
HAVING 
    MAX(at.production_year) < 2020 
ORDER BY 
    latest_movie_year DESC
LIMIT 10;