WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(mi.info) AS description
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    GROUP BY 
        m.movie_id
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorSummary AS (
    SELECT 
        ft.actor_name,
        COUNT(DISTINCT ft.movie_title) AS total_movies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(mi.description, 'No description available') AS movie_description
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        TitleKeywords k ON ft.movie_title = k.title_id
    LEFT JOIN 
        MovieInfo mi ON ft.movie_title = mi.description
    GROUP BY 
        ft.actor_name, mi.description
)
SELECT 
    actor_name,
    total_movies,
    keywords,
    movie_description
FROM 
    ActorSummary
WHERE 
    total_movies > 2
ORDER BY 
    total_movies DESC, actor_name;
