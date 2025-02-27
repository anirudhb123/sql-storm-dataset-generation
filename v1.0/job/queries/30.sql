WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
AverageRatings AS (
    SELECT 
        mi.movie_id,
        AVG(CASE WHEN mi.info IS NOT NULL THEN CAST(mi.info AS FLOAT) ELSE 0 END) AS avg_rating
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
    GROUP BY 
        mi.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    tk.keywords,
    ar.actor_name,
    ar.role,
    COALESCE(ar.nr_order, 0) AS actor_order,
    COALESCE(avg.avg_rating, 0.0) AS average_rating
FROM 
    RankedTitles tt
LEFT JOIN 
    TitleKeywords tk ON tt.title_id = tk.movie_id
LEFT JOIN 
    ActorRoles ar ON tt.title_id = ar.movie_id AND ar.nr_order < 5
LEFT JOIN 
    AverageRatings avg ON tt.title_id = avg.movie_id
WHERE 
    tt.year_rank <= 5
ORDER BY 
    tt.production_year DESC, tt.title ASC;
