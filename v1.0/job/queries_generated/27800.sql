WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
),

TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
    HAVING 
        COUNT(c.id) > 2
),

MovieDetails AS (
    SELECT 
        tt.title,
        tt.production_year,
        ta.actor_name,
        RANK() OVER (PARTITION BY tt.title ORDER BY ta.role_count DESC) AS actor_rank
    FROM 
        RankedTitles tt
    JOIN 
        TopActors ta ON tt.title_id = ta.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    CASE 
        WHEN md.actor_rank = 1 THEN 'Best Actor'
        WHEN md.actor_rank <= 3 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_category
FROM 
    MovieDetails md
WHERE 
    md.actor_rank <= 5
ORDER BY 
    md.production_year DESC, 
    md.title;
