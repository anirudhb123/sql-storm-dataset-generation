
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    COALESCE(t.name, 'Unknown Actor') AS leading_actor,
    COALESCE(m.keywords, 'No keywords') AS movie_keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = r.title_id AND cc.status_id IS NULL) AS pending_complete_cast
FROM 
    RankedTitles r
LEFT JOIN 
    TopActors t ON r.title_id = (SELECT ci.movie_id 
                                  FROM cast_info ci 
                                  WHERE ci.person_role_id = (SELECT id FROM role_type WHERE role = 'leading' LIMIT 1) 
                                  AND ci.movie_id = r.title_id 
                                  ORDER BY ci.nr_order LIMIT 1)
LEFT JOIN 
    MoviesWithKeywords m ON r.title_id = m.movie_id
WHERE 
    r.title_rank <= 3
ORDER BY 
    r.production_year DESC, r.title;
